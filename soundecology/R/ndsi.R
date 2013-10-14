#
#Gage's Soundscape Index
# From REAL - Remote Environmental Assessment Laboratory
# http://www.real.msu.edu/
#
# Also from: Krause, Bernie, Stuart H. Gage, and Wooyeong Joo. 2011. 
#  Measuring and interpreting the temporal variability in the soundscape
#  at four places in Sequoia National Park. Landscape Ecol. DOI 10.1007/s10980-011-9639-6
#
# Also from: Kasten, Eric P., Stuart H. Gage, Jordan Fox, and Wooyeong Joo. 2012.
#  The Remote Environmental Assessment Laboratory’s Acoustic Library: An Archive for 
#  Studying Soundscape Ecology. Ecological Informatics 12: 50–67. doi:10.1016/j.ecoinf.2012.08.001.
#
# "The samples were converted to 22 kHz monaural. A normalized Power Spectrum
#  Density value (PSD in Watt/Hz) (Welch 1967) was
#  computed for each 1 kHz interval for all recordings
#  by running a script programmed by Gage and Joo
#  using MATLAB (Gilat 2004)."
#
# "Normalized Difference Soundscape Index (NDSI) is a numeric indicator of a
#  soundscape's relative biological composition to human disturbance based
#  on the amount of acoustic energy in different frequency bands. The distribution 
#  of sound frequencies in acoustic samples was computed to determine what 
#  types of sounds occurred (e.g., mechanical, biological or physical) at 
#  different frequencies. Normalized ratios of frequency levels were then 
#  calculated to evaluate the relative amounts of Biophony (biological sounds) 
#  or Anthrophony (human-induced sounds) in a set of samples. 
#  The equation for NDSI is: 
#  
#    NDSI = (β - α) / (β + α)
#  
#  where α, β represent the proportion of acoustic energy of Anthrophony and 
#  Biophony, respectively. The value of the index ranges from -1 to 1. If the 
#  value is negative, mechanical sounds dominate the soundscape. If the value 
#  approaches 1, most of the soundscape consists of biological sounds at the site."
#
#  "The NDSI is computed as the ratio of the sound intensity found in the 
#  frequencies where biological sounds (biophony) are most prevalent (2-8 kHz)
#  to the frequencies where mechanical sounds (technophony) are most prevalent
#  (1-2 kHz). NDSI has values in the range +1 to -1, with +1 indicating that 
#  a signal contains only biophony. As shown in the figure, NDSI has a larger 
#  biophonic component between 2100 and 0730 hours."
#
#
# REQUIRES the packages tuneR, seewave, pracma, oce
#

ndsi <- function(soundfile, fft_w=1024, anthro_min=1000, anthro_max=2000, bio_min=2000, bio_max=11000){
	
	#Some general values
	hz_interval = anthro_max - anthro_min
	
	#Get sampling rate
	samplingrate <- soundfile@samp.rate
	duration <- length(soundfile@left)/soundfile@samp.rate
	
	#Get Nyquist frequency in Hz
	nyquist_freq <- (samplingrate/2)
	
	#Check errors
	if (bio_max > nyquist_freq) {
	  stop(paste("The maximum frequency of biophony (", bio_max, " Hz) can not be higher than the maximum frequency of the file (", nyquist_freq, " Hz)\n\n Change the value of bio_max to less than ", nyquist_freq, "\n\n", sep=""))
	}
  
	if (anthro_max > bio_min) {
	  stop(paste("The maximum frequency of anthrophony (", anthro_max, " Hz) can not be higher than the minimum frequency of biophony (", bio_min, " Hz)\n\n Change the value of anthro_max to equal or less than bio_min\n\n", sep=""))
	}
  
	if (anthro_max < anthro_min) {
	  stop(paste("The minimum frequency of anthrophony (", anthro_min, " Hz) can not be higher than the maximum frequency of anthrophony (", anthro_max, " Hz)\n\n Change the value of anthro_min to less than anthro_max\n\n", sep=""))
	}
  
	if (bio_max < bio_min) {
	  stop(paste("The minimum frequency of biophony (", bio_min, " Hz) can not be higher than the maximum frequency of biophony (", bio_max, " Hz)\n\n Change the value of anthro_min to less than anthro_max\n\n", sep=""))
	}
	 
  
	#Stereo file
	if (soundfile@stereo==TRUE) {
		cat("\n This is a stereo file. Results will be given for each channel.\n")
		
		left <- channel(soundfile, which = c("left"))
		right <- channel(soundfile, which = c("right"))
		rm(soundfile)
		
		cat("\n Calculating index. Please wait... \n\n")
		
		#LEFT CHANNEL
		left1 <- cutw(left, from=0, to=length(left@left)/left@samp.rate)
		#Compute the Welch periodogram
		specA_left <- pwelch(left1, fs=samplingrate, nfft=fft_w, plot=FALSE)
		
		specA_left <- specA_left$spec
		specA_rows <- length(specA_left)
		
		freq_per_row <- specA_rows/nyquist_freq
		
		anthro_vals_range <- anthro_max - anthro_min
		bio_vals_range <- bio_max - bio_min
		bio_bins <- round(bio_vals_range/hz_interval)
		
		anthro_bins <- rep(NA, round(anthro_vals_range/hz_interval))
		bio_bins <- rep(NA, round(bio_vals_range/hz_interval))
		
		anthro_min_row <- round(anthro_min * freq_per_row)
		anthro_max_row <- round(anthro_max * freq_per_row)
		bio_step_range <- freq_per_row * (bio_vals_range/length(bio_bins))
		bio_min_row <- round(bio_min * freq_per_row)
		bio_max_row <- bio_min_row + bio_step_range
		
		
		#Get the area for each bin of anthrophony and biophony
			#Anthrophony		
			for (i in 1:length(anthro_bins)){
			  anthro_bins[i] <- trapz(specA_left[anthro_min_row:anthro_max_row])
			}
			
			#Biophony  	
			for (i in 1:length(bio_bins)){
				
				if (bio_max_row >= specA_rows){
					bio_max_row <- specA_rows
				}
				
			  bio_bins[i] <- trapz(specA_left[bio_min_row:bio_max_row])
			  
			  bio_min_row <- bio_min_row + bio_step_range
			  bio_max_row <- bio_max_row + bio_step_range
			}
		
		freqbins <- rep(NA, sum(length(anthro_bins), length(bio_bins)))
		freqbins <- c(anthro_bins, bio_bins)
		#Normalize
		freqbins = freqbins / norm(as.matrix(freqbins), "F");
		
		#All bins
		freqbins.SumAll <- sum(freqbins)
		#All biophony bins
		freqbins.SumBio <- sum(freqbins[2:length(freqbins)])
		#Single anthrophony bin
		freqbins.Anthro <- freqbins[1]
		
		#Result
		NDSI_left <- (freqbins.SumBio - freqbins.Anthro)/(freqbins.SumBio + freqbins.Anthro)
		
		#Right channel
		right1 <- cutw(right, from=0, to=length(right@left)/right@samp.rate)
		specA_right <- pwelch(right1, fs=samplingrate, nfft=fft_w, plot=FALSE)
		
		#with pwelch
		specA_right <- specA_right$spec
		specA_rows <- length(specA_right)
		
		freq_per_row <- specA_rows/nyquist_freq
		
		anthro_vals_range <- anthro_max - anthro_min
		bio_vals_range <- bio_max - bio_min
		bio_bins <- round(bio_vals_range/hz_interval)
		
		anthro_bins <- rep(NA, round(anthro_vals_range/hz_interval))
		bio_bins <- rep(NA, round(bio_vals_range/hz_interval))
		
		anthro_min_row <- round(anthro_min * freq_per_row)
		anthro_max_row <- round(anthro_max * freq_per_row)
		bio_step_range <- freq_per_row * (bio_vals_range/length(bio_bins))
		bio_min_row <- round(bio_min * freq_per_row)
		bio_max_row <- bio_min_row + bio_step_range
		
		#Anthrophony		
		for (i in 1:length(anthro_bins)){
		  anthro_bins[i] <- trapz(specA_right[anthro_min_row:anthro_max_row])
		}
		
		#Biophony  	
		for (i in 1:length(bio_bins)){
			
			if (bio_max_row >= specA_rows){
				bio_max_row <- specA_rows
			}
			
		  bio_bins[i] <- trapz(specA_right[bio_min_row:bio_max_row])
		  
		  bio_min_row <- bio_min_row + bio_step_range
		  bio_max_row <- bio_max_row + bio_step_range
		}
		
		freqbins <- rep(NA, sum(length(anthro_bins), length(bio_bins)))
		freqbins <- c(anthro_bins, bio_bins)
		freqbins = freqbins / norm(as.matrix(freqbins), "F");
		
		
		freqbins.SumAll <- sum(freqbins)
		freqbins.SumBio <- sum(freqbins[2:length(freqbins)])
		freqbins.Anthro <- freqbins[1]
		
		NDSI_right <- (freqbins.SumBio - freqbins.Anthro)/(freqbins.SumBio + freqbins.Anthro)
				
    
		cat("\n NDSI left channel: ")
		cat(NDSI_left)
		cat("\n")
		cat(" NDSI right channel: ")
		cat(NDSI_right)
		cat("\n\n")
	} else 
	{
		cat("\n This is a mono file.\n")
		
		#LEFT CHANNEL
		left<-channel(soundfile, which = c("left"))
		rm(soundfile)
		
		cat("\n Calculating index. Please wait... \n\n")
		
		left1 <- cutw(left, from=0, to=length(left@left)/left@samp.rate)
		specA_left <- pwelch(left1, fs=samplingrate, nfft=fft_w, plot=FALSE)
    
		#with pwelch
		specA_left <- specA_left$spec
		specA_rows <- length(specA_left)
		
		freq_per_row <- specA_rows/nyquist_freq
		
		anthro_vals_range <- anthro_max - anthro_min
		bio_vals_range <- bio_max - bio_min
		bio_bins <- round(bio_vals_range/hz_interval)
		
		anthro_bins <- rep(NA, round(anthro_vals_range/hz_interval))
		bio_bins <- rep(NA, round(bio_vals_range/hz_interval))
		
		anthro_min_row <- round(anthro_min * freq_per_row)
		anthro_max_row <- round(anthro_max * freq_per_row)
		bio_step_range <- freq_per_row * (bio_vals_range/length(bio_bins))
		bio_min_row <- round(bio_min * freq_per_row)
		bio_max_row <- bio_min_row + bio_step_range
		
		#Anthrophony		
		for (i in 1:length(anthro_bins)){
		  anthro_bins[i] <- trapz(specA_left[anthro_min_row:anthro_max_row])
		}
		
		#Biophony  	
		for (i in 1:length(bio_bins)){
			
			if (bio_max_row >= specA_rows){
				bio_max_row <- specA_rows
				}

		  bio_bins[i] <- trapz(specA_left[bio_min_row:bio_max_row])
		  
		  bio_min_row <- bio_min_row + bio_step_range
		  bio_max_row <- bio_max_row + bio_step_range
		}
		
		freqbins <- rep(NA, sum(length(anthro_bins), length(bio_bins)))
		freqbins <- c(anthro_bins, bio_bins)
		freqbins = freqbins / norm(as.matrix(freqbins), "F");
		
		
    freqbins.SumAll <- sum(freqbins)
		freqbins.SumBio <- sum(freqbins[2:length(freqbins)])
		freqbins.Anthro <- freqbins[1]
    
    NDSI_left <- (freqbins.SumBio - freqbins.Anthro)/(freqbins.SumBio + freqbins.Anthro)
    
    #Right channel
		NDSI_right = NA
		
		cat("\n NDSI: ")
		cat(NDSI_left)
		cat("\n\n")
	}
	invisible(list(ndsi_left=NDSI_left, ndsi_right=NDSI_right))
}