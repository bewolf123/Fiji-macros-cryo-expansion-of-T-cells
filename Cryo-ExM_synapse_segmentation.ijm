
//--- Segmentation of the cells based on the Actin Channel---
// This macro is designed to work with .lif files from Leica, containing thunder lightning images with the Lng_LVCC denoising treatment

run("Close All");

// get the data directory
dirdata = getDirectory("Choose the folder you would like to analyze");
// Create a Segmentation folder to save the segmented cell ROI
dir_roi = dirdata+"Segmented"+File.separator();
File.makeDirectory(dir_roi); 

// Extension of the files
extension = "Lng_LVCC";
ext_size = lengthOf(extension);

// Select the channels of interest
Dialog.create("What is the channel number to segment?");
Dialog.addNumber("Indicate the channel number to segment the cells", 2);
Dialog.show();
staining_nb = Dialog.getNumber();


Dialog.create("What is the dapi channel?");
Dialog.addNumber("Indicate the Dapi channel number", 4);
Dialog.show();
Dapi_nb = Dialog.getNumber();


/// tableau contenant le nom des fichier contenus dans le dossier dirdata
ImageNames=getFileList(dirdata);
nbimages=lengthOf(ImageNames); 

cell_nb = -1;

if(isOpen("Results")) {
		selectWindow("Results");
		run("Close");
		}
		
if(isOpen("ROI Manager")) {
	roiManager("reset");
	}


nbSerieMax=50;
series=newArray();
for(i=1; i<nbSerieMax; i=i+1) {
	series[i] = "series_"+i+" ";
}


// Open all the lif files-------------------------------------------------------------------------------
for (i=0; i<lengthOf(ImageNames); i++) { // Loop over images contained in dirdata

	// Open all images and Roi
	 if (endsWith(ImageNames[i], ".lif")) {
		name_size = lengthOf(ImageNames[i]) - 4;
		LifName=substring(ImageNames[i],0 ,name_size);
		print(LifName);
		
		for(image_serie=0 ; image_serie<nbSerieMax; image_serie++){
		run("Bio-Formats", "open=["+dirdata+ImageNames[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT use_virtual_stack "+series[image_serie]);
		
			Name = getTitle();
		
			
			// segment only the Lng_LVCC images
			if (endsWith(Name, extension)) {
				Serie_nb = substring(Name,lengthOf(Name)-12,lengthOf(Name)-9);
				print("Series_number", Serie_nb);
				
				
				// Adjust colors and channels
				Stack.setPosition(staining_nb,15,1);
				Stack.setChannel(staining_nb);
				run("Enhance Contrast", "saturated=0.35");

				Stack.setPosition(Dapi_nb,50,1);
				Stack.setChannel(4);
				run("Enhance Contrast", "saturated=0.35");
				
				
				if(isOpen("ROI Manager")) {
					roiManager("reset");					
				}
				
				Stack.setPosition(staining_nb,15,1);
				
				
//------------- Segmentation with nucleus------------------------------------------------------------
				selectWindow(Name);
				run("Duplicate...", "title=DAPI duplicate channels="+Dapi_nb);
				run("Z Project...", "projection=[Max Intensity]"); //Note: For some images, resluts are more acurate with a "[Sum Slices]"
				wait(500);

			
				// segmentation via DAPI channel
				run("Mean...", "radius=50");
				run("Find Maxima...", "noise=500 output=[Segmented Particles]");
				rename("Mask_DAPI");
				close("MAX_DAPI");
				close("DAPI");
				
//-------------- Make Cell Mask using the defined channel-------------------------------------------------------------------------
				selectWindow(Name);
				run("Duplicate...", "title=Actin duplicate channels="+staining_nb);
				// Work with Z-projection
				run("Z Project...", "projection=[Sum Slices]"); //Note: For some images, resluts are more acurate with a "[Max intensity]"
				wait(500);
				run("Gaussian Blur...", "sigma=5");
				run("Unsharp Mask...", "radius=4 mask=0.8 stack"); //Note: Adjust radiuss if the segmentation is not accurate
				setAutoThreshold("Huang dark no-reset");
				run("Convert to Mask");
				run("Fill Holes");
				rename("Mask_Actin");
				close("Actin");
			
//-------------- Combine Masks-------------------------------------------------------------------------
				imageCalculator("AND create", "Mask_DAPI","Mask_Actin");
				selectWindow("Result of Mask_DAPI");				
		
				run("Analyze Particles...", "size=300-Infinity overlay add"); //Note: the size parameter can be adjusted depending on the cell size
				
				close("Result of Mask_DAPI");
				close("Mask_Actin");
				close("Mask_DAPI");
				
				
				
				selectWindow(Name);
				roiManager("Show All");
				
				
				
				roiManager("Save", dir_roi + LifName+"_serie"+Serie_nb+"RoiSet.zip");
				
				close(Name);

				}else {
				close(Name);
				}
				
	 		}
	 	}
	 }
run("Tile");
showMessage("Your cell segmentation is done, check if you need to correct manually");
				
	
		
				
				
				
				
				
				
				
				