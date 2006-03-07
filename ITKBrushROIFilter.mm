//
//  ITKBrushROIFilter.m
//  OsiriX
//
//  Created by joris on 2/16/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#define id Id
#include "Accelerate.h"
#include "itkImage.h"
#include "itkImportImageFilter.h"
#include "itkBinaryErodeImageFilter.h"
#include "itkBinaryDilateImageFilter.h"
#include "itkBinaryBallStructuringElement.h"
#undef id

#import "ROI.h"
#import "ITKBrushROIFilter.h"

typedef unsigned char TPixel;
typedef itk::Image<TPixel, 2> ImageType;
typedef itk::BinaryBallStructuringElement<TPixel, 2> StucturingElementType;
typedef itk::ImportImageFilter<TPixel, 2> ImportFilterType;

void draw_filled_circle(unsigned char *buf, int width, unsigned char val)
{
	int		x,y;
	int		xsqr;
	int		inw = width-1;
	int		radsqr = (inw*inw)/4;
	int		rad = width/2;
	
	for(x = 0; x < rad; x++)
	{
		xsqr = x*x;
		for( y = 0 ; y < rad; y++)
		{
			if((xsqr + y*y) < radsqr)
			{
				buf[ rad+x + (rad+y)*width] = val;
				buf[ rad-x + (rad+y)*width] = val;
				buf[ rad+x + (rad-y)*width] = val;
				buf[ rad-x + (rad-y)*width] = val;
			}
		}
	}
}

// Erosion
typedef itk::BinaryErodeImageFilter<ImageType,ImageType,StucturingElementType> ErodeFilterType;
// Dilatation
typedef itk::BinaryDilateImageFilter<ImageType,ImageType,StucturingElementType> DilateFilterType;

ImageType::Pointer CreateImagePointerFromBuffer(unsigned char *buffer, int bufferWidth, int bufferHeight)
{
	ImportFilterType::Pointer importFilter = ImportFilterType::New();
	
	ImportFilterType::SizeType size;
	size[0] = bufferWidth; // size along X
	size[1] = bufferHeight; // size along Y

	ImportFilterType::IndexType start;
	start[0] = 0;
	start[1] = 0;

	ImportFilterType::RegionType region;
	region.SetIndex(start);
	region.SetSize(size);
	importFilter->SetRegion(region);

	double origin[2];
	origin[0] = 0.0; // X coordinate
	origin[1] = 0.0; // Y coordinate
	importFilter->SetOrigin(origin);

	double spacing[2];
	spacing[0] = 1.0; // along X direction
	spacing[1] = 1.0; // along Y direction
	importFilter->SetSpacing(spacing); 

	const bool importImageFilterWillOwnTheBuffer = false;
	importFilter->SetImportPointer(buffer, size[0]*size[1], importImageFilterWillOwnTheBuffer);
	importFilter->Update();

	ImageType::Pointer image = importFilter->GetOutput();

	return image;
}

@implementation ITKBrushROIFilter

// filters
- (void) erode:(ROI*)aROI withStructuringElementRadius:(int)structuringElementRadius
{
	// input buffer
	unsigned char *buff = [aROI textureBuffer];
	int bufferWidth = [aROI textureWidth];
	int bufferHeight = [aROI textureHeight];
	
	
	// vImage TEST	: 0.01 s -> 200 times faster than ITK
	
	structuringElementRadius *= 2;
	structuringElementRadius ++;
	
	unsigned char *kernel;
	kernel = (unsigned char*) calloc( structuringElementRadius*structuringElementRadius, sizeof(unsigned char));
	draw_filled_circle(kernel, structuringElementRadius, 0xFF);	
	
	vImage_Buffer	srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = buff;
	dstBuf.data = malloc( bufferHeight * bufferWidth);
	dstBuf.height = srcbuf.height = bufferHeight;
	dstBuf.width = srcbuf.width = bufferWidth;
	dstBuf.rowBytes = srcbuf.rowBytes = bufferWidth;
	err = vImageErode_Planar8( &srcbuf, &dstBuf, 0, 0, kernel, structuringElementRadius, structuringElementRadius, kvImageDoNotTile);
	if( err) NSLog(@"%d", err);
	
	BlockMoveData(dstBuf.data,buff,bufferWidth*bufferHeight);
	free( dstBuf.data);
	free( kernel);
	
	[aROI reduceTextureIfPossible];
	
//	// buffer to ITK image
//	ImageType::Pointer inputROI = CreateImagePointerFromBuffer(buff, bufferWidth, bufferHeight);
//	// erosion filter
//	ErodeFilterType::Pointer binaryErode = ErodeFilterType::New();
//	// structuring Element
//	StucturingElementType structuringElement;
//	structuringElement.SetRadius(structuringElementRadius);
//	structuringElement.CreateStructuringElement();
//	// parameters
//	binaryErode->SetKernel(structuringElement);
//	binaryErode->SetErodeValue(255);
//	// process
//	binaryErode->SetInput(inputROI);
//	binaryErode->Update();
//	// output
//	inputROI = binaryErode->GetOutput();
//	// update the ROI
//	unsigned char *erodedBuffer = inputROI->GetBufferPointer();
//	BlockMoveData(erodedBuffer,buff,bufferWidth*bufferHeight*sizeof(char));
}

- (void) dilate:(ROI*)aROI withStructuringElementRadius:(int)structuringElementRadius
{	
	// add a margin to avoid border effects
	[aROI addMarginToBuffer: structuringElementRadius*2];
	
	// input buffer
	unsigned char *buff = [aROI textureBuffer];
	int bufferWidth = [aROI textureWidth];
	int bufferHeight = [aROI textureHeight];
	
	// vImage TEST	: 0.01 s -> 200 times faster than ITK
	
	structuringElementRadius *= 2;
	structuringElementRadius ++;
	
	unsigned char *kernel;
	kernel = (unsigned char*) calloc( structuringElementRadius*structuringElementRadius, sizeof(unsigned char));
	memset(kernel,0xff,structuringElementRadius*structuringElementRadius);
	draw_filled_circle(kernel, structuringElementRadius, 0x0);
	
	vImage_Buffer	srcbuf, dstBuf;
	vImage_Error err;
	srcbuf.data = buff;
	dstBuf.data = malloc( bufferHeight * bufferWidth);
	dstBuf.height = srcbuf.height = bufferHeight;
	dstBuf.width = srcbuf.width = bufferWidth;
	dstBuf.rowBytes = srcbuf.rowBytes = bufferWidth;
	err = vImageDilate_Planar8( &srcbuf, &dstBuf, 0, 0, kernel, structuringElementRadius, structuringElementRadius, kvImageDoNotTile);
	if( err) NSLog(@"%d", err);
	
	BlockMoveData(dstBuf.data,buff,bufferWidth*bufferHeight);
	free( dstBuf.data);
	free( kernel);
	
	[aROI reduceTextureIfPossible];
	// buffer to ITK image : 2 s
//	ImageType::Pointer inputROI = CreateImagePointerFromBuffer(buff, bufferWidth, bufferHeight);
//	// dilatation filter
//	DilateFilterType::Pointer binaryDilate = DilateFilterType::New();
//	// structuring Element
//	StucturingElementType structuringElement;
//	structuringElement.SetRadius(structuringElementRadius);
//	structuringElement.CreateStructuringElement();
//	// parameters
//	binaryDilate->SetKernel(structuringElement);
//	binaryDilate->SetDilateValue(255);
//	// process
//	binaryDilate->SetInput(inputROI);
//	binaryDilate->Update();
//	// output
//	inputROI = binaryDilate->GetOutput();
//	// update the ROI
//	unsigned char *erodedBuffer = inputROI->GetBufferPointer();
//	BlockMoveData(erodedBuffer,buff,bufferWidth*bufferHeight*sizeof(char));
}

- (void) close:(ROI*)aROI withStructuringElementRadius:(int)structuringElementRadius
{
	[self dilate:aROI withStructuringElementRadius:structuringElementRadius];
	[self erode:aROI withStructuringElementRadius:structuringElementRadius];
}

- (void) open:(ROI*)aROI withStructuringElementRadius:(int)structuringElementRadius
{
	[self erode:aROI withStructuringElementRadius:structuringElementRadius];
	[self dilate:aROI withStructuringElementRadius:structuringElementRadius];
}

@end
