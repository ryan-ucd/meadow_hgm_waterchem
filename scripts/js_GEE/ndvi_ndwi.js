// export feature table with mean, median, stdDev values from landsat collections

// subset for only Van Norden
var meadows = ee.FeatureCollection('ft:15vFFI1Y--ZqBTRX2K2tPomsR4_W_LCw7KtUIuGtq')
  .filter(ee.Filter.eq('NAME', 'Van Norden'));

Map.addLayer(meadows, '', 'Meadows');


// metric to export using EE 8-day composites
var index = 'NDVI' ;// 'NDVI' or 'NDWI'

////////////////////////////////////////////
//  landsat 5
var land5 = ee.ImageCollection('LANDSAT/LT5_L1T_8DAY_' + index).filterBounds(meadows.geometry().bounds());
// landsat 7
var land7 = ee.ImageCollection('LANDSAT/LE7_L1T_8DAY_' + index).filterBounds(meadows.geometry().bounds());
// landsat 8
var land8 = ee.ImageCollection('LANDSAT/LC8_L1T_8DAY_' + index).filterBounds(meadows.geometry().bounds());
// combine all from 5, 7, 8
var combined = ee.ImageCollection(land5.merge(land7).merge(land8));


print(combined.size());

/////////////////////////////////////////////////////
// summarizes region and add system id property
var reducers = function(img){
  var source = img.get("system:id");// get souce info from img
  var fc = meadows.map(function(feature){var fc = feature.set({source: source}); return(fc)}); // set img source by mapping over fc
  
  //reduce regions
  var red = img.reduceRegions({
    'collection': fc,
    'reducer': ee.Reducer.mean().combine(ee.Reducer.stdDev(), "", true).combine(ee.Reducer.median(), "", true),
    'scale': 60, //30 errors out
    'tileScale': 8 // increase tile scale if running out of memory. 
  });
  

  var red_n = red.filter(ee.Filter.neq('mean', null)); //filter out any null values
  return(red_n);
  };
  

// map reducers over the image collection.
var results = ee.FeatureCollection(combined.map(reducers));

// flatten the results
results = results.flatten();

// Make a feature without geometry and set the properties to the dictionary of means.
var strip_geo = function(feature){
  var new_feature = feature.select(["ID", "source", "mean", "median", "stdDev"], null , false);
  return new_feature;
};

// Map the strip geo function over the results.
var selected_export = results.map(strip_geo);

// print out the first result to the console to check that it works
print(selected_export.first());

Export.table(selected_export, "mdws_batch_" + index);