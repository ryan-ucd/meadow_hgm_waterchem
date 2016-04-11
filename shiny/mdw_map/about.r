tabPanel("About",
         HTML(
           '<p style="text-align:justify">This R Shiny web application presents LANDSAT satellite derived NDVI and NDWI for various all UCDSNMC v.1 meadows greater than ~1.5 hectares.
           This highlights both similarities in patterns across montane meadows in the Sierra Nevada as well as the large degree of variation. With climate warming, there is uncertainty about the future of these complex
           ecosystems. Understanding which meadows may be more resilient, and whether LANDSAT data may be useful to identify the sensitivity of these meadows by permitting fine scale spatiotemporal analysis using indices like NDVI and NDWI.
           See the <a href="http://meadows.ucdavis.edu/">Sierra Nevada Multi-Source Meadow Polygons Compilation</a> documentation for more information.</p>'),
         
         HTML('
              <div style="clear: left;"><img src="https://watershed.ucdavis.edu/files/styles/medium/public/images/users/RyanPeek1.JPG?itok=uJfL4TVh" alt="" style="float: left; margin-right:5px" /></div>
              <div style="clear: left;"><img src="https://watershed.ucdavis.edu/files/styles/medium/public/images/users/andy_bell_headshot_2014.jpg?itok=seavuPmZ.png" alt="" style="float: left; margin-right:5px" /></div>
              <p>Ryan Peek<br/>
              <p>Andy Bell<br/>
              Researchers at Center for Watershed Sciences | Ecology <br/>
              <a href="http://blog.snap.uaf.edu" target="_blank">Blog</a> | 
              <a href="https://twitter.com/riverpeek" target="_blank">Twitter</a> | 
              <a href="http://watershed.ucdavis.edu/", target="_blank">Center for Watershed Sciences</a>
              </p>'),
         
         fluidRow(
           column(4,
                  HTML('<strong>References</strong>
                       <p></p><ul>
                       <li><a href="http://www.r-project.org/" target="_blank">Coded in R</a></li>
                       <li><a href="http://www.rstudio.com/shiny/" target="_blank">Built with the Shiny package</a></li>
                       <li>Additional supporting R packages</li>
                       <ul>
                       <li><a href="http://rstudio.github.io/shinythemes/" target="_blank">shinythemes</a></li>
                       <li><a href="https://github.com/ebailey78/shinyBS" target="_blank">shinyBS</a></li>
                       <li><a href="http://rstudio.github.io/leaflet/" target="_blank">leaflet</a></li>
                       </ul>')
           )
         ),
         value="about"
)