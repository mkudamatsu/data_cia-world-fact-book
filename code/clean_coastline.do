/* Takes ## seconds to run */

* Program Setup
version 15     			      // Set Version number for backward compatibility
set more off           		// Disable partitioned output
clear all							    // Start with a clean slate
capture log close					// Close the log if accidentally still open
timer clear 1             // Clear timer
timer on 1                // Record how long this do file takes to be run

/* The working directory must be the root of the project folder. */

* Table of Contents (the main function)
capture program drop main
program define main
	* Inputs
  import delimited country coastline_original using "./orig/coastline.csv", clear

  * process
  clean_data

	* Output
	capture mkdir data
	save_output "./data/coastline.dta"
end

* Subfunctions that appear within the main function
capture program drop clean_data
program define clean_data

  * Key variable
  lab var country "Country name"
  * Original variable
  lab var coastline_original "Coastline length as appears in CIA World Fact Book"
  * Cleaned variable
  gen coastline = coastline_original
  lab var coastline "Coastline length (km)"

  * Landlocked
  replace coastline = "0" if regexm(coastline_original, "landlocked")
  * End with " km"
  replace coastline = substr(coastline_original, 1, strlen(coastline_original) - 3) if regexm(coastline_original, "km$") // See https://www.statalist.org/forums/forum/general-stata-discussion/general/1408707-drop-the-last-4-characters-of-a-string
  * End with " km (blah blah blah)"
  foreach num of numlist 1(1)10 {
    replace coastline = substr(coastline_original, 1, `num'-2) if strpos(coastline_original, "km") == `num'
  }
  * Deal with France (which has two entries, one for mainland France and the other for overseas territories included)
  drop if country == "France" // This is for France including overseas territories
  replace country = "France" if regexm(coastline_original, "metropolitan France")
  replace coastline = substr(coastline_original, -8, 5) if regexm(coastline_original, "metropolitan France")

  * Remove comma for thousands
  replace coastline = subinstr(coastline, ",", "", .)

  * Drop unnecessary data (mostly island territories)
  drop if country == ""
  drop if country == "United States Pacific Island Wildlife Refuges"
  drop if country == "French Southern and Antarctic Lands"
  drop if country == "South Georgia and South Sandwich Islands"
  drop if country == "Saint Helena, Ascension, and Tristan da Cunha"

  destring coastline, replace

end

capture program drop save_output
program define save_output
	args filename
	display "Saving disk space"
	compress
	display "Saving as Stata data"
	save `filename', replace
end

capture program drop install_package
program define install_package
	args package_name source_url
	capture which `package_name'
	if _rc == 111 {
		net install `package_name', from(`source_url') replace
		}
end

* Internal functions that appear within the subfunctions

* Execute the whole script
*log using "./log/.log", replace // Keep the log
set trace on						// Trace the execution of the program line by line
main
set trace off						// Turn off the tracing

timer off 1             // Stop the timer
timer list              // Show how long this do file took to be run

* Closing commands
*log close							// Close the log
*exit, STATA clear					// Exit Stata
