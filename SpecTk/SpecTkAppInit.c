/* 
 * tkAppInit.c --
 *
 *	Provides a default version of the Tcl_AppInit procedure for
 *	use in wish and similar Tk-based applications.
 *
 * Copyright (c) 1993 The Regents of the University of California.
 * Copyright (c) 1994-1997 Sun Microsystems, Inc.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: tkAppInit.c,v 1.7 2002/06/21 20:24:29 dgp Exp $
 */

#include <tk.h>
//#include <tcl.h>
//#include "locale.h"
#include <math.h>
//#include <tkDecls.h>
#include <blt.h>
#include <string.h>
#include <stdlib.h>
#include "nrutil.h"

#ifdef TK_TEST
extern int		Tktest_Init _ANSI_ARGS_((Tcl_Interp *interp));
#endif /* TK_TEST */

/*
 *----------------------------------------------------------------------
 *
 * main --
 *
 *	This is the main program for the application.
 *
 * Results:
 *	None: Tk_Main never returns here, so this procedure never
 *	returns either.
 *
 * Side effects:
 *	Whatever the application does.
 *
 *----------------------------------------------------------------------
 */

int
main(int argc, char **argv)
//    int argc;			/* Number of command-line arguments. */
//    char **argv;		/* Values of command-line arguments. */
{
    /*
     * The following #if block allows you to change the AppInit
     * function by using a #define of TCL_LOCAL_APPINIT instead
     * of rewriting this entire file.  The #if checks for that
     * #define and uses Tcl_AppInit if it doesn't exist.
     */
    
#ifndef TK_LOCAL_APPINIT
#define TK_LOCAL_APPINIT Tcl_AppInit    
#endif
    extern int TK_LOCAL_APPINIT _ANSI_ARGS_((Tcl_Interp *interp));
    
    /*
     * The following #if block allows you to change how Tcl finds the startup
     * script, prime the library or encoding paths, fiddle with the argv,
     * etc., without needing to rewrite Tk_Main()
     */
    
#ifdef TK_LOCAL_MAIN_HOOK
    extern int TK_LOCAL_MAIN_HOOK _ANSI_ARGS_((int *argc, char ***argv));
    TK_LOCAL_MAIN_HOOK(&argc, &argv);
#endif

    Tk_Main(argc, argv, TK_LOCAL_APPINIT);
    return 0;			/* Needed only to prevent compiler warning. */
}

// This section contains the implementations of additional commands
// needed by SpecTk
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// Functionality
/*-------------------------------------------------------------
	CSet2DImage Command
	
	Implements the command:
		set2Dimage image vectors limits thresholds palette
	where:
	- image is a photo image previously defined
	- vectors is a list containing the {x y z} vectors of a Wave2D
	- limits is the list {xchmin ychmin xchmax ychmax}
	- thresholds is a Tcl list containing the z scale thresholds
	- palette is a Tcl list containing the corresponding colors
	This command builds an image plot of a 2D list wave
---------------------------------------------------------------*/

int Set2DImageProc(
	ClientData clientData,
	Tcl_Interp *interp,
	int argc,
	const char *argv[]
	)
{
	Tk_PhotoHandle		handle;
	int							listArgc;
// patch difference in declared listArgv between 8.3 and 8.4
# if TCL_MINOR_VERSION==3
	char				**listArgv;
# endif
# if TCL_MINOR_VERSION==4
	const char				**listArgv;
# endif
# if TCL_MINOR_VERSION==6
	const char				**listArgv;
# endif
	Blt_Vector				*vector[3];
	Tk_PhotoImageBlock	*iBlock, *image;
	char						str[80];
	double					*data;
	int 						xpix, ypix, pw, ph;
	int 						xchmin, ychmin, xchmax, ychmax;
	double					*thresholds;
	int							levels;
	int							il, it, thresend, thresfirst;
	unsigned short			*test;
	unsigned int			nz = 1 << 16;
	XColor					**palette;
	int							colors;
	int							ic;
	Tk_Window				tkwin = Tk_MainWindow(interp);
	Tk_Uid					id;
	XColor					*background=NULL;
	unsigned long 			i, n;
	unsigned long			pxadd;
	unsigned long			xx, yy, xxf, xxl, yyf, yyl;
	unsigned long			x, y, xf, xl, yf, yl, ynx, ypx, pxval, chval;
	unsigned short			red, blue, green, index;
	int 						numValues;
	double 					xv, yv, zv;
	double 					xmin, xmax, ymin, ymax;

// This command must have 5 arguments
	if (argc < 6) {
		Tcl_SetResult(interp,
"Usage:\n\
  Set2DImage image vectors limits thresholds palette [-background color]\n\
    where:\n\
    - image is a photo image previously defined\n\
    - vectors is a list containing the {x y z} vectors of a Wave2D\n\
    - limits is the list {xchmin ychmin xchmax ychmax}\n\
    - thresholds is a Tcl list containing the z scale thresholds\n\
    - palette is a Tcl list containing the corresponding colors",
		TCL_STATIC);
    	return TCL_ERROR;
	}
	
// First argument should be an existing image
	handle = Tk_FindPhoto(interp, argv[1]);
	if (handle == NULL) {
		sprintf(str, "Photo image %s doesn't exist!", argv[1]);
		Tcl_SetResult(interp, str, TCL_VOLATILE);
		return TCL_ERROR;
	}
	
	xpix = 0;
	ypix = 0;
	Tk_PhotoGetSize(handle, &pw, &ph);

// Second argument should be a list of 3 vectors
	if (Tcl_SplitList(interp, argv[2], &listArgc, &listArgv) != TCL_OK)
		return TCL_ERROR;
	if (listArgc != 3) {
		Tcl_SetResult(interp, "vectors must contain 3 vector names", TCL_STATIC);
		return TCL_ERROR;
	}
	for (i=0; i<3; i++) {
		if (Blt_GetVector(interp, (char*)listArgv[i], &vector[i]) != TCL_OK)
			return TCL_ERROR;
	}
//	free((char*) listArgv);

// Third argument should be a list containing xchmin ychmin xchmax ychmax

	if (Tcl_SplitList(interp, argv[3], &listArgc, &listArgv) != TCL_OK)
		return TCL_ERROR;
	if (listArgc != 4) {
		Tcl_SetResult(interp, "limits must be {xchmin ychmin xchmax ychmax}", TCL_STATIC);
		return TCL_ERROR;
	}
	if (Tcl_GetInt(interp, listArgv[0], &xchmin) != TCL_OK)
		return TCL_ERROR;
	if (Tcl_GetInt(interp, listArgv[1], &ychmin) != TCL_OK)
		return TCL_ERROR;
	if (Tcl_GetInt(interp, listArgv[2], &xchmax) != TCL_OK)
		return TCL_ERROR;
	if (Tcl_GetInt(interp, listArgv[3], &ychmax) != TCL_OK)
		return TCL_ERROR;
//	free((char*) listArgv);

// Fourth argument should be a list containing the thresholds

	if (Tcl_SplitList(interp, argv[4], &listArgc, &listArgv) != TCL_OK)
		return TCL_ERROR;
	levels = listArgc;
	if (levels == 0) {
		Tcl_SetResult(interp, "threshold list must contain at least one value", TCL_STATIC);
		return TCL_ERROR;
	}
	thresholds = (double*)malloc(sizeof(double)*levels);
//	thresholds = new double[levels];
	for (il=0; il<levels; il++) {
		if (Tcl_GetDouble(interp, listArgv[il], &thresholds[il]) != TCL_OK) {
			sprintf(str, "invalid threshold entry: %s", listArgv[il]);
			Tcl_SetResult(interp, str, TCL_VOLATILE);
			return TCL_ERROR;
		}
	}
	
// Fifth argument should contain the palette of colors

	if (Tcl_SplitList(interp, argv[5], &listArgc, &listArgv) != TCL_OK)
		return TCL_ERROR;
	colors = listArgc;
	if (colors != levels) {
		Tcl_SetResult(interp, "palette list must have the same number of items as threshold list", TCL_STATIC);
		return TCL_ERROR;
	}
	palette = (XColor**)malloc(sizeof(XColor*)*colors);
//	palette = new XColor*[colors];
	for (ic=0; ic<colors; ic++) {
		id = Tk_GetUid(listArgv[ic]);
		palette[ic] = Tk_GetColor(interp, tkwin, id);
		if (palette[ic] == NULL) {
			sprintf(str, "Color %s not found", listArgv[ic]);
			Tcl_SetResult(interp, str, TCL_VOLATILE);
			return TCL_ERROR;
		}
	}
	
// Options
	if (argc > 6) {
		for (i=6; i<argc; i+=2) {
			if (strcmp(argv[i], "-background") == 0) {
				id = Tk_GetUid(argv[i+1]);
				background = Tk_GetColor(interp, tkwin, id);
				if (background == NULL) {
					sprintf(str, "Color %s not found", argv[i+1]);
					Tcl_SetResult(interp, str, TCL_VOLATILE);
					return TCL_ERROR;
				}
			} else {
				sprintf(str, "unknown option: %s", argv[i]);
				Tcl_SetResult(interp, str, TCL_VOLATILE);
				return TCL_ERROR;
			}
		}
	}

// Now that all arguments have been parsed, the real work starts
// First allocate the memory in which we will draw the image
	iBlock = (Tk_PhotoImageBlock*)malloc(sizeof(Tk_PhotoImageBlock));
//	iBlock = new Tk_PhotoImageBlock;
	iBlock->pixelPtr = (unsigned char*)malloc(sizeof(unsigned char)*pw*ph*3);
//	iBlock->pixelPtr = new unsigned char[pw*ph*3];
// Set the Tk_PhotoImageBlock structure
	iBlock->width = pw;
	iBlock->height = ph;
	iBlock->pixelSize = 3;
	iBlock->pitch = pw * 3;
	iBlock->offset[0] = 0;
	iBlock->offset[1] = 1;
	iBlock->offset[2] = 2;
	iBlock->offset[3] = 0;
	if (background == NULL) {
// Zero the pixel array (black background)
		memset(iBlock->pixelPtr, 0, pw*ph*3);
	} else {
// or set the background color
		for (i=0; i<pw*ph*3; i+=3) {
			iBlock->pixelPtr[i] = (char)background->red;
			iBlock->pixelPtr[i+1] = (char)background->green;
			iBlock->pixelPtr[i+2] = (char)background->blue;
		}
	}
	data = (double*)malloc(sizeof(double)*pw*ph);
//	data = new double[pw*ph];
	memset(data, 0, pw*ph*sizeof(double));

	numValues = vector[0]->numValues;
	xmin = (double)xchmin;
	xmax = (double)xchmax;
	ymin = (double)ychmin;
	ymax = (double)ychmax;

// we loop on the data list
	for (n=0; n<numValues; n++) {
		xv = vector[0]->valueArr[n];
		yv = vector[1]->valueArr[n];
		zv = vector[2]->valueArr[n];
// if the data is outside the display range it won't show		
		if (xv < xmin || xv >= xmax || yv < ymin || yv >= ymax) continue;
// if the data is less than the minimum threshold it won't show
//		if (zv < (double)thresfirst) continue;
		if (zv < thresholds[0]) continue;
		xf = lrint((xv-xmin)/(xmax-xmin)*(pw-1));
		xl = lrint((xv+1-xmin)/(xmax-xmin)*(pw-1));
		if (xl == xf) xl++;
		yf = lrint((yv-ymin)/(ymax-ymin)*(ph-1));
		yl = lrint((yv+1-ymin)/(ymax-ymin)*(ph-1));
		if (yl == yf) yl++;
// data reduction: if we had lit this pixel up already with a larger value keep it
		pxadd = (xf + pw * (ph-1-yf));
		if (data[pxadd] >= zv) continue;
		data[pxadd] = zv;
		index = levels-1;
		if (zv < thresholds[index]) {
			while (zv < thresholds[index]) {
				index--;
				if (index == 0) break;
			}
		}
		red = palette[index]->red;
		green = palette[index]->green;
		blue = palette[index]->blue;
//		pxval = lrint(zv + 0.5);
//		red = palette[test[pxval]]->red;
//		green = palette[test[pxval]]->green;
//		blue = palette[test[pxval]]->blue;
		for (y=yf; y<yl; y++) {
			ypx = pw * (ph-1-y);
			for (x=xf; x<xl; x++) {
				pxadd = (x + ypx) * 3;
				iBlock->pixelPtr[pxadd++] = (char)red;
				iBlock->pixelPtr[pxadd++] = (char)green;
				iBlock->pixelPtr[pxadd] = (char)blue;
			}
		}
	}


// Put the image data into the photo image
	Tk_PhotoBlank(handle);
# if TCL_MINOR_VERSION==3
	Tk_PhotoPutBlock(handle, iBlock, xpix, ypix, pw, ph);
# endif
# if TCL_MINOR_VERSION==4
	Tk_PhotoPutBlock(handle, iBlock, xpix, ypix, pw, ph,TK_PHOTO_COMPOSITE_OVERLAY);
# endif
# if TCL_MINOR_VERSION==6
	Tk_PhotoPutBlock(interp, handle, iBlock, xpix, ypix, pw, ph,TK_PHOTO_COMPOSITE_OVERLAY);
# endif
	
// Clean up
	free(iBlock->pixelPtr);
	free(iBlock);
	free(palette);
	free(thresholds);
	free(data);
	
	return TCL_OK;
}


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// IsInsidePolygon
/* ======= Crossings Multiply algorithm =================================== */
// From D. Haines code
int IsInsidePolygon(
	double x,
	double y,
	double *xp,
	double *yp,
	int np
	)
{
	register int j, yflag0, yflag1, inside;
	register double vtx0, vty0, vtx1, vty1;
	
	vtx0 = xp[np-1];
	vty0 = yp[np-1];
	yflag0 = (vty0 >= y);
	inside = 0;
	vtx1 = xp[0];
	vty1 = yp[0];

	for (j=1; j<=np; j++) {
		yflag1 = (vty1 >= y);
		if (yflag0 != yflag1) {
			if ( ((vty1-y) * (vtx0-vtx1) >= (vtx1-x) * (vty0-vty1)) == yflag1 ) {
				inside = !inside;
			}
		}
		yflag0 = yflag1;
		vtx0 = vtx1;
		vty0 = vty1;
		vtx1 = xp[j];
		vty1 = yp[j];
	}
	
	return (inside);
}

		
// Functionality
/*-------------------------------------------------------------
	CWave2DInPolygon Command
	
	Implements the command:
		Wave2DInPolygon xpolygon ypolygon scale wvectors pvectors
	where:
	- xpolygon is a list describing the x coordinates of the polygon: {x0 x1 x2 É}
	- ypolygon is a list describing the y coordinates of the polygon: {y0 y1 y2 É}
	- scale is a list describing the scaling: {xlow ylow xinc yinc}
	- wvectors is a list containing the {x y z} vectors of the Wave2D
	- pvectors is a list of empty (or not) {x y z} vectors to be filled
	This command selects bins inside the polygon and returns them in pvectors.
---------------------------------------------------------------*/

int Wave2DInPolygonProc(
	ClientData clientData,
	Tcl_Interp *interp,
	int argc,
	const char *argv[]
	)
{
	int					listArgc;
// patch difference in declared listArgv between 8.3 and 8.4
# if TCL_MINOR_VERSION==3
	char				**listArgv;
# endif
# if TCL_MINOR_VERSION==4
	const char				**listArgv;
# endif
# if TCL_MINOR_VERSION==6
	const char				**listArgv;
# endif
	Blt_Vector		*wv[3], *pv[3];
	char				str[80];
	int					npoly;
	double			*xpoly, *ypoly, *xbpoly, *ybpoly;
	double			xlow, ylow, xinc, yinc;
	int					i;
	int					ndata;
	double			xbmin=1e30, xbmax=-1e30, ybmin=1e30, ybmax=-1e30;
	double			xv, yv;
	int					index=0;

// This command must have 5 arguments
	if (argc < 6) {
		Tcl_SetResult(interp,
"Usage:\n\
  Wave2DInPolygon xpolygon ypolygon scale wvectors pvectors\n\
    where:\n\
      - xpolygon is a list describing the x coordinates of the polygon: {x0 x1 x2 É}\n\
      - ypolygon is a list describing the y coordinates of the polygon: {y0 y1 y2 É}\n\
      - scale is a list describing the scaling: {xlow ylow xinc yinc}\n\
      - wvectors is a list containing the {x y z} vectors of the Wave2D\n\
      - pvectors is a list of empty (or not) {x y z} vectors to be filled",
		TCL_STATIC);
    	return TCL_ERROR;
	}
	
// First argument is a list of coordinates describing the x coordinates of the polygon
	if (Tcl_SplitList(interp, argv[1], &listArgc, &listArgv) != TCL_OK) return TCL_ERROR;
	npoly = listArgc;
	xpoly = (double*)malloc(sizeof(double)*npoly);
	xbpoly = (double*)malloc(sizeof(double)*npoly);
//	xpoly = new double[npoly];
//	xbpoly = new double[npoly];
	for (i=0; i<npoly; i++) {
		if (Tcl_GetDouble(interp, listArgv[i], &xpoly[i]) != TCL_OK) {
			sprintf (str, "invalid xpolygon entry: %s", listArgv[i]);
			Tcl_SetResult(interp, str, TCL_VOLATILE);
			return TCL_ERROR;
		}
	}
//	free((char*) listArgv);
	
// Second argument is a list of coordinates describing the y coordinates of the polygon
	if (Tcl_SplitList(interp, argv[2], &listArgc, &listArgv) != TCL_OK) return TCL_ERROR;
	if (npoly != listArgc) {
		Tcl_SetResult(interp, "invalid: the xpolygon and ypolygon lists have different lengthes", TCL_STATIC);
		return TCL_ERROR;
	}
	ypoly = (double*)malloc(sizeof(double)*npoly);
	ybpoly = (double*)malloc(sizeof(double)*npoly);
	for (i=0; i<npoly; i++) {
		if (Tcl_GetDouble(interp, listArgv[i], &ypoly[i]) != TCL_OK) {
			sprintf (str, "invalid ypolygon entry: %s", listArgv[i]);
			Tcl_SetResult(interp, str, TCL_VOLATILE);
			return TCL_ERROR;
		}
	}
//	free((char*) listArgv);

// Third argument contains the scaling information of the Wave2D
	if (Tcl_SplitList(interp, argv[3], &listArgc, &listArgv) != TCL_OK) return TCL_ERROR;
	if (listArgc != 4) {
		Tcl_SetResult(interp, "invalid: the scale list must contain the 4 members {xlow ylow xinc yinc}", TCL_STATIC);
		return TCL_ERROR;
	}
	if (Tcl_GetDouble(interp, listArgv[0], &xlow) != TCL_OK) {
		Tcl_SetResult(interp, "invalid xlow entry", TCL_STATIC);
		return TCL_ERROR;
	}
	if (Tcl_GetDouble(interp, listArgv[1], &ylow) != TCL_OK) {
		Tcl_SetResult(interp, "invalid ylow entry", TCL_STATIC);
		return TCL_ERROR;
	}
	if (Tcl_GetDouble(interp, listArgv[2], &xinc) != TCL_OK) {
		Tcl_SetResult(interp, "invalid xinc entry", TCL_STATIC);
		return TCL_ERROR;
	}
	if (Tcl_GetDouble(interp, listArgv[3], &yinc) != TCL_OK) {
		Tcl_SetResult(interp, "invalid yinc entry", TCL_STATIC);
		return TCL_ERROR;
	}
//	free((char*) listArgv);

// Fourth argument contains a list of the Wave2D {x y z} vectors
	if (Tcl_SplitList(interp, argv[4], &listArgc, &listArgv) != TCL_OK) return TCL_ERROR;
	if (listArgc != 3) {
		Tcl_SetResult(interp, "invalid: the list must contain the 3 Wave2D vectors {x y z}", TCL_STATIC);
		return TCL_ERROR;
	}
	for (i=0; i<3; i++) {
		if (Blt_GetVector(interp, (char*)listArgv[i], &wv[i]) != TCL_OK) {
			sprintf (str, "invalid vector name: %s", listArgv[i]);
			Tcl_SetResult(interp, str, TCL_VOLATILE);
			return TCL_ERROR;
		}
	}
//	free((char*) listArgv);
	
// Fifth argument contains a list of {x y z} vectors to be filled
	if (Tcl_SplitList(interp, argv[5], &listArgc, &listArgv) != TCL_OK) return TCL_ERROR;
	if (listArgc != 3) {
		Tcl_SetResult(interp, "invalid: the list must contain the 3 vectors {x y z}", TCL_STATIC);
		return TCL_ERROR;
	}
	for (i=0; i<3; i++) {
		if (Blt_GetVector(interp, (char*)listArgv[i], &pv[i]) != TCL_OK) {
			sprintf (str, "invalid vector name: %s", listArgv[i]);
			Tcl_SetResult(interp, str, TCL_VOLATILE);
			return TCL_ERROR;
		}
	}
//	free((char*) listArgv);
	
// Resize vectors to contain selected data - could be as big as the input Wave2D itself
	ndata = wv[0]->numValues;
	Blt_ResizeVector(pv[0], ndata);
	Blt_ResizeVector(pv[1], ndata);
	Blt_ResizeVector(pv[2], ndata);
	
// Transform the polygon coordinates to bins and find boundaries
	for (i=0; i<npoly; i++) {
		xbpoly[i] = (xpoly[i]-xlow)/xinc;
		ybpoly[i] = (ypoly[i]-ylow)/yinc;
		if (xbpoly[i] < xbmin) xbmin = xbpoly[i];
		if (xbpoly[i] > xbmax) xbmax = xbpoly[i];
		if (ybpoly[i] < ybmin) ybmin = ybpoly[i];
		if (ybpoly[i] > ybmax) ybmax = ybpoly[i];
	}
	
// Loop on data and select bins inside polygon
	for (i=0; i<ndata; i++) {
		xv = wv[0]->valueArr[i];
		if (xv < xbmin || xv > xbmax) continue;
		yv = wv[1]->valueArr[i];
		if (yv < ybmin || yv > ybmax) continue;
		if (IsInsidePolygon(xv, yv, xbpoly, ybpoly, npoly)) {
			pv[0]->valueArr[index] = xv;
			pv[1]->valueArr[index] = yv;
			pv[2]->valueArr[index] = wv[2]->valueArr[i];
			index++;
		}
	}
	
// Resize result vectors
	Blt_ResizeVector(pv[0], index);
	Blt_ResizeVector(pv[1], index);
	Blt_ResizeVector(pv[2], index);

// Clean up
	free(xpoly);
	free(xbpoly);
	free(ypoly);
	free(ybpoly);
	
	return TCL_OK;
}


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// Functionality
/*-------------------------------------------------------------
	CFitIterate Command
	
	Implements the command:
		FitIterate
	which implements a fitting command from
	a Tcl script based on the Numerical Recipes
	function mrqmin.
---------------------------------------------------------------*/

int FitIterateProc(
	ClientData clientData,
	Tcl_Interp *interp,
	int argc,
	const char *argv[]
	)
{
// Pointer to a function used to select different fitting functions
	static void (*fitfunction)(double, double[], double*, double[], int);
// BLT vectors contain the input data, fitted coefficients and fitted function
	static Blt_Vector *vx, *vy, *vsig;
	static Blt_Vector *va, *verr, *vhold;
	static Blt_Vector *fx, *fy;
// Internal arrays used between iterations of the fit
	static int *ia;
	static double *x, *y, *sig, *a, *dyda, **covar, **alpha;
// Internal variables
	static int ma, npt, quiet;
	static double alamda, chisq;
// Fitting program from Numerical Recipes (Levenberg-Marquardt method)
	void mrqmin(double x[], double y[], double sig[], int ndata, double a[], int ia[],
	int ma, double **covar, double **alpha, double *chisq,
	void (*funcs)(double, double[], double*, double[], int), double *alamda);
	extern short gNumrecError;
	void gaussian(double, double[], double*, double[], int);
	void lorentzian(double, double[], double*, double[], int);
	void exponential(double, double[], double*, double[], int);
	void polynomial(double, double[], double*, double[], int);
	char str[80];
	int		i;
	
	int					listArgc;
// patch difference in declared listArgv between 8.3 and 8.4
# if TCL_MINOR_VERSION==3
	char				**listArgv;
# endif
# if TCL_MINOR_VERSION==4
	const char				**listArgv;
# endif
# if TCL_MINOR_VERSION==6
	const char				**listArgv;
# endif

// Usage
	if (argc < 2) {
		Tcl_SetResult(interp,
"Usage:\n\
	FitIterate configure ?option? ?value?\n\
	FitIterate cget ?option? ?value?\n\
	FitIterate init ?option? ?values?\n\
	FitIterate iterate\n\
	FitIterate finish\n",
		TCL_STATIC);
		return TCL_OK;
	}

// configure
	if (strcmp(argv[1], "configure") == 0) {
		if (strcmp(argv[2], "-function") == 0) {
			fitfunction = &gaussian;
			if (strcmp(argv[3], "lorentzian") == 0) fitfunction = &lorentzian;
			if (strcmp(argv[3], "exponential") == 0) fitfunction = &exponential;
			if (strcmp(argv[3], "polynomial") == 0) fitfunction = &polynomial;
		}
		if (strcmp(argv[2], "-quiet") == 0) {
			if (Tcl_GetInt(interp, argv[3], &quiet) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid value - should be 0 or 1", TCL_STATIC);
				return TCL_ERROR;
			}
		}
	}

// cget
	if (strcmp(argv[1], "cget") == 0) {
		if (strcmp(argv[2], "-function") == 0) {
			if (fitfunction == &gaussian) Tcl_SetResult(interp, "gaussian", TCL_STATIC);
			if (fitfunction == &lorentzian) Tcl_SetResult(interp, "lorentzian", TCL_STATIC);
			if (fitfunction == &exponential) Tcl_SetResult(interp, "exponential", TCL_STATIC);
			if (fitfunction == &polynomial) Tcl_SetResult(interp, "polynomial", TCL_STATIC);
		}
		if (strcmp(argv[2], "-quiet") == 0) {
			if (quiet) Tcl_SetResult(interp, "1", TCL_STATIC);
			else Tcl_SetResult(interp, "0", TCL_STATIC);
		}
	}

// init
	if (strcmp(argv[1], "init") == 0) {
// input
		if (strcmp(argv[2], "-input") == 0) {
			if (argc != 6) {
				Tcl_SetResult(interp, "Invalid # of arguments - should be: FitIterate init -input x y sig", TCL_STATIC);
				return TCL_ERROR;
			}
			if (Blt_GetVector(interp, (char*)argv[3], &vx) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid BLT vector for x", TCL_STATIC);
				return TCL_ERROR;
			}
			if (Blt_GetVector(interp, (char*)argv[4], &vy) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid BLT vector for y", TCL_STATIC);
				return TCL_ERROR;
			}
			if (Blt_GetVector(interp, (char*)argv[5], &vsig) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid BLT vector for sig", TCL_STATIC);
				return TCL_ERROR;
			}
			if (vx->numValues != vy->numValues || vx->numValues != vsig->numValues || vy->numValues != vsig->numValues) {
				Tcl_SetResult(interp, "Error: vectors x, y and sig must have the same number of points", TCL_STATIC);
				return TCL_ERROR;
			}
			npt = vx->numValues;
			x = (double*)dVector(1, npt);
			y = (double*)dVector(1, npt);
			sig = (double*)dVector(1, npt);
			for (i=0; i<npt; i++) {
				x[i+1] = vx->valueArr[i];
				y[i+1] = vy->valueArr[i];
				sig[i+1] = vsig->valueArr[i];
			}
		}
// coefficients
		if (strcmp(argv[2], "-coefficient") == 0) {
			if (argc != 6) {
				Tcl_SetResult(interp, "Invalid # of arguments - should be: FitIterate init -coefficient coeff error hold", TCL_STATIC);
				return TCL_ERROR;
			}
			if (Blt_GetVector(interp, (char*)argv[3], &va) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid BLT vector for coeff", TCL_STATIC);
				return TCL_ERROR;
			}
			if (Blt_GetVector(interp, (char*)argv[4], &verr) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid BLT vector for error", TCL_STATIC);
				return TCL_ERROR;
			}
			if (Blt_GetVector(interp, (char*)argv[5], &vhold) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid BLT vector for hold", TCL_STATIC);
				return TCL_ERROR;
			}
			ma = va->numValues;
			ia = (int*)iVector(1, ma);
			a = (double*)dVector(1, ma);
			dyda = (double*)dVector(1, ma);
			covar = dmatrix(1, ma, 1, ma);
			alpha = dmatrix(1, ma, 1, ma);
			for (i=0; i<ma; i++) {
				if (vhold->valueArr[i] == 0) ia[i+1] = 1;
				else ia[i+1] = 0;
				a[i+1] = va->valueArr[i];
			}
		}
// output
		if (strcmp(argv[2], "-output") == 0) {
			if (argc != 5) {
				Tcl_SetResult(interp, "Invalid # of arguments - should be: FitIterate init -output fx fy", TCL_STATIC);
				return TCL_ERROR;
			}
			if (Blt_GetVector(interp, (char*)argv[3], &fx) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid BLT vector for fx", TCL_STATIC);
				return TCL_ERROR;
			}
			if (Blt_GetVector(interp, (char*)argv[4], &fy) != TCL_OK) {
				Tcl_SetResult(interp, "Invalid BLT vector for fy", TCL_STATIC);
				return TCL_ERROR;
			}
		}
// fit
		if (strcmp(argv[2], "-fit") == 0) {
			if (argc != 3) {
				Tcl_SetResult(interp, "Invalid # of arguments - should be: FitIterate init -fit", TCL_STATIC);
				return TCL_ERROR;
			}
			gNumrecError = 0;
			alamda = -1;
			mrqmin(x, y, sig, npt, a, ia, ma, covar, alpha, &chisq, *fitfunction, &alamda);
		}
	}

// iterate
	if (strcmp(argv[1], "iterate") == 0) {
		mrqmin(x, y, sig, npt, a, ia, ma, covar, alpha, &chisq, *fitfunction, &alamda);
		if (gNumrecError == 1) {
			Tcl_SetResult(interp, "-1", TCL_STATIC);
			return TCL_OK;
		}
		for (i=0; i<ma; i++) {
			va->valueArr[i] = a[i+1];
			verr->valueArr[i] = sqrt(covar[i+1][i+1]);
		}
		if (!quiet) {
			for (i=0; i<fx->numValues; i++) {
				fitfunction(fx->valueArr[i], a, &fy->valueArr[i], dyda, ma);
			}
		}
		sprintf(str, "%g", chisq);
		Tcl_SetResult(interp, str, TCL_VOLATILE);
	}

// finish
	if (strcmp(argv[1], "finish") == 0) {
		alamda = 0;
		mrqmin(x, y, sig, npt, a, ia, ma, covar, alpha, &chisq, *fitfunction, &alamda);
		for (i=0; i<ma; i++) {
			va->valueArr[i] = a[i+1];
			verr->valueArr[i] = sqrt(covar[i+1][i+1]);
		}
		for (i=0; i<fx->numValues; i++) {
			fitfunction(fx->valueArr[i], a, &fy->valueArr[i], dyda, ma);
		}
		sprintf(str, "%g", chisq);
		Tcl_SetResult(interp, str, TCL_VOLATILE);
		free_dmatrix(alpha, 1, ma, 1, ma);
		free_dmatrix(covar, 1, ma, 1, ma);
		free_iVector(ia, 1, ma);
		free_dVector(a, 1, ma);
		free_dVector(dyda, 1, ma);
		free_dVector(x, 1, npt);
		free_dVector(y, 1, npt);
		free_dVector(sig, 1, npt);
	}

	return TCL_OK;
}

// Fitting functions

void gaussian(double x, double a[], double *y, double dyda[], int na)
{
  // Gaussian with linear background
  double arg, ex, fac;
  arg = (x - a[4]) / a[5] / sqrt(2);
  ex = exp(-arg * arg);
  fac = a[3] * ex * 2 * arg;
  *y = a[3] * ex + a[1] + a[2] * (x - a[4]);
  dyda[1] = 1;
  dyda[2] = x - a[4];
  dyda[3] = ex;
  dyda[4] = fac / a[5] / sqrt(2);
  dyda[5] = fac * arg / a[5] / sqrt(2);
}

void lorentzian(double x, double a[], double *y, double dyda[], int na)
{
  // Lorentzian with linear background
  double arg, ex, fac;
  arg = (x - a[4]) * (x - a[4]) + a[5];
  *y = a[1] + a[2] * (x - a[4]) + a[3] / arg;
  dyda[1] = 1;
  dyda[2] = x - a[4];
  dyda[3] = 1 / arg;
  dyda[4] = a[3] / arg / arg * 2 * (x - a[4]);
  dyda[5] = -a[3] / arg / arg;
}

void exponential(double x, double a[], double *y, double dyda[], int na)
{
	double fac;
	fac = exp(-a[4]*x);
	*y = a[1] + a[2] * x + a[3] * fac;
	dyda[1] = 1;
	dyda[2] = x;
	dyda[3] = fac;
	dyda[4] = -x * a[3] * fac;
}

void polynomial(double x, double a[], double *y, double dyda[], int na)
{
	double fac;
	int	 i;
	*y = 0;
	for (i=1; i <= na; i++) {
		fac = pow(x, i-1);
		*y += a[i] * fac;
		dyda[i] = fac;
	}
}


/*
 *----------------------------------------------------------------------
 *
 * Tcl_AppInit --
 *
 *	This procedure performs application-specific initialization.
 *	Most applications, especially those that incorporate additional
 *	packages, will have their own version of this procedure.
 *
 * Results:
 *	Returns a standard Tcl completion code, and leaves an error
 *	message in the interp's result if an error occurs.
 *
 * Side effects:
 *	Depends on the startup script.
 *
 *----------------------------------------------------------------------
 */

int
Tcl_AppInit(Tcl_Interp *interp)
//    Tcl_Interp *interp;		/* Interpreter for application. */
{
    if (Tcl_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    if (Tk_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Tk", Tk_Init, Tk_SafeInit);
#ifdef TK_TEST
    if (Tktest_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
    Tcl_StaticPackage(interp, "Tktest", Tktest_Init,
            (Tcl_PackageInitProc *) NULL);
#endif /* TK_TEST */


    /*
     * Call the init procedures for included packages.  Each call should
     * look like this:
     *
     * if (Mod_Init(interp) == TCL_ERROR) {
     *     return TCL_ERROR;
     * }
     *
     * where "Mod" is the name of the module.
     */

    /*
     * Call Tcl_CreateCommand for application-specific commands, if
     * they weren't already created by the init procedures called above.
     */
	Tcl_CreateCommand(interp, "Set2DImage", Set2DImageProc,
	(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "Wave2DInPolygon", Wave2DInPolygonProc,
	(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "FitIterate", FitIterateProc,
	(ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
    /*
     * Specify a user-specific startup file to invoke if the application
     * is run interactively.  Typically the startup file is "~/.apprc"
     * where "app" is the name of the application.  If this line is deleted
     * then no user-specific startup file will be run under any conditions.
     */

	char spectkhome[120], *charpt;
	charpt = getenv("SpecTkHome");
	if (charpt != NULL) {
		strcpy(spectkhome, charpt);
		charpt = spectkhome+strlen(spectkhome);
		strcpy(charpt, "/Main.tcl");
	} else {
		strcpy(spectkhome, "Main.tcl");
	}
    Tcl_SetVar(interp, "tcl_rcFileName", spectkhome, TCL_GLOBAL_ONLY);
    return TCL_OK;
}

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// Numerical Recipes stuff
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

void mrqmin(double x[], double y[], double sig[], int ndata, double a[], int ia[],
	int ma, double **covar, double **alpha, double *chisq,
	void (*funcs)(double, double [], double *, double [], int), double *alamda)
{
	void covsrt(double **covar, int ma, int ia[], int mfit);
	void gaussj(double **a, int n, double **b, int m);
	void mrqcof(double x[], double y[], double sig[], int ndata, double a[],
		int ia[], int ma, double **alpha, double beta[], double *chisq,
		void (*funcs)(double, double [], double *, double [], int));
	int j,k,l,m;
	static int mfit;
	static double ochisq,*atry,*beta,*da,**oneda;

	if (*alamda < 0.0) {
		atry=dVector(1,ma);
		beta=dVector(1,ma);
		da=dVector(1,ma);
		for (mfit=0,j=1;j<=ma;j++)
			if (ia[j]) mfit++;
		oneda=dmatrix(1,mfit,1,1);
		*alamda=0.001;
		mrqcof(x,y,sig,ndata,a,ia,ma,alpha,beta,chisq,funcs);
		ochisq=(*chisq);
		for (j=1;j<=ma;j++) atry[j]=a[j];
	}
	for (j=0,l=1;l<=ma;l++) {
		if (ia[l]) {
			for (j++,k=0,m=1;m<=ma;m++) {
				if (ia[m]) {
					k++;
					covar[j][k]=alpha[j][k];
				}
			}
			covar[j][j]=alpha[j][j]*(1.0+(*alamda));
			oneda[j][1]=beta[j];
		}
	}
	gaussj(covar,mfit,oneda,1);
	for (j=1;j<=mfit;j++) da[j]=oneda[j][1];
	if (*alamda == 0.0) {
		covsrt(covar,ma,ia,mfit);
		free_dmatrix(oneda,1,mfit,1,1);
		free_dVector(da,1,ma);
		free_dVector(beta,1,ma);
		free_dVector(atry,1,ma);
		return;
	}
	for (j=0,l=1;l<=ma;l++)
		if (ia[l]) atry[l]=a[l]+da[++j];
	mrqcof(x,y,sig,ndata,atry,ia,ma,covar,da,chisq,funcs);
	if (*chisq < ochisq) {
		*alamda *= 0.1;
		ochisq=(*chisq);
		for (j=0,l=1;l<=ma;l++) {
			if (ia[l]) {
				for (j++,k=0,m=1;m<=ma;m++) {
					if (ia[m]) {
						k++;
						alpha[j][k]=covar[j][k];
					}
				}
				beta[j]=da[j];
				a[l]=atry[l];
			}
		}
	} else {
		*alamda *= 10.0;
		*chisq=ochisq;
	}
}

void mrqcof(double x[], double y[], double sig[], int ndata, double a[], int ia[],
	int ma, double **alpha, double beta[], double *chisq,
	void (*funcs)(double, double [], double *, double [], int))
{
	int i,j,k,l,m,mfit=0;
	double ymod,wt,sig2i,dy,*dyda;

	dyda=dVector(1,ma);
	for (j=1;j<=ma;j++)
		if (ia[j]) mfit++;
	for (j=1;j<=mfit;j++) {
		for (k=1;k<=j;k++) alpha[j][k]=0.0;
		beta[j]=0.0;
	}
	*chisq=0.0;
	for (i=1;i<=ndata;i++) {
		(*funcs)(x[i],a,&ymod,dyda,ma);
		sig2i=1.0/(sig[i]*sig[i]);
		dy=y[i]-ymod;
		for (j=0,l=1;l<=ma;l++) {
			if (ia[l]) {
				wt=dyda[l]*sig2i;
				for (j++,k=0,m=1;m<=l;m++)
					if (ia[m]) alpha[j][++k] += wt*dyda[m];
				beta[j] += dy*wt;
			}
		}
		*chisq += dy*dy*sig2i;
	}
	for (j=2;j<=mfit;j++)
		for (k=1;k<j;k++) alpha[k][j]=alpha[j][k];
	free_dVector(dyda,1,ma);
}

#define SWAP(a,b) {temp=(a);(a)=(b);(b)=temp;}

void gaussj(double **a, int n, double **b, int m)
{
	int *indxc,*indxr,*ipiv;
	int i,icol,irow,j,k,l,ll;
	double big,dum,pivinv,temp;

	indxc=iVector(1,n);
	indxr=iVector(1,n);
	ipiv=iVector(1,n);
	for (j=1;j<=n;j++) ipiv[j]=0;
	for (i=1;i<=n;i++) {
		big=0.0;
		for (j=1;j<=n;j++)
			if (ipiv[j] != 1)
				for (k=1;k<=n;k++) {
					if (ipiv[k] == 0) {
						if (fabs(a[j][k]) >= big) {
							big=fabs(a[j][k]);
							irow=j;
							icol=k;
						}
					} else if (ipiv[k] > 1) nrerror("gaussj: Singular Matrix-1");
				}
		++(ipiv[icol]);
		if (irow != icol) {
			for (l=1;l<=n;l++) SWAP(a[irow][l],a[icol][l])
			for (l=1;l<=m;l++) SWAP(b[irow][l],b[icol][l])
		}
		indxr[i]=irow;
		indxc[i]=icol;
		if (a[icol][icol] == 0.0) nrerror("gaussj: Singular Matrix-2");
		pivinv=1.0/a[icol][icol];
		a[icol][icol]=1.0;
		for (l=1;l<=n;l++) a[icol][l] *= pivinv;
		for (l=1;l<=m;l++) b[icol][l] *= pivinv;
		for (ll=1;ll<=n;ll++)
			if (ll != icol) {
				dum=a[ll][icol];
				a[ll][icol]=0.0;
				for (l=1;l<=n;l++) a[ll][l] -= a[icol][l]*dum;
				for (l=1;l<=m;l++) b[ll][l] -= b[icol][l]*dum;
			}
	}
	for (l=n;l>=1;l--) {
		if (indxr[l] != indxc[l])
			for (k=1;k<=n;k++)
				SWAP(a[k][indxr[l]],a[k][indxc[l]]);
	}
	free_iVector(ipiv,1,n);
	free_iVector(indxr,1,n);
	free_iVector(indxc,1,n);
}
#undef SWAP

#define SWAP(a,b) {swap=(a);(a)=(b);(b)=swap;}

void covsrt(double **covar, int ma, int ia[], int mfit)
{
	int i,j,k;
	double swap;

	for (i=mfit+1;i<=ma;i++)
		for (j=1;j<=i;j++) covar[i][j]=covar[j][i]=0.0;
	k=mfit;
	for (j=ma;j>=1;j--) {
		if (ia[j]) {
			for (i=1;i<=ma;i++) SWAP(covar[i][k],covar[i][j])
			for (i=1;i<=ma;i++) SWAP(covar[k][i],covar[j][i])
			k--;
		}
	}
}
#undef SWAP

short gNumrecError;

#define NR_END 1
#define FREE_ARG char*

void nrerror(char error_text[])
/* Numerical Recipes standard error handler */
{
	fprintf(stderr,"Numerical Recipes run-time error...\n");
	fprintf(stderr,"%s\n",error_text);
	//	fprintf(stderr,"...now exiting to system...\n");
	//	exit(1);
	gNumrecError = 1;
}

double *Vector(long nl, long nh)
/* allocate a double Vector with subscript range v[nl..nh] */
{
	double *v;

	v=(double *)malloc((size_t) ((nh-nl+1+NR_END)*sizeof(double)));
	if (!v) nrerror("allocation failure in Vector()");
	return v-nl+NR_END;
}

int *iVector(long nl, long nh)
/* allocate an int Vector with subscript range v[nl..nh] */
{
	int *v;

	v=(int *)malloc((size_t) ((nh-nl+1+NR_END)*sizeof(int)));
	if (!v) nrerror("allocation failure in iVector()");
	return v-nl+NR_END;
}

unsigned char *cVector(long nl, long nh)
/* allocate an unsigned char Vector with subscript range v[nl..nh] */
{
	unsigned char *v;

	v=(unsigned char *)malloc((size_t) ((nh-nl+1+NR_END)*sizeof(unsigned char)));
	if (!v) nrerror("allocation failure in cVector()");
	return v-nl+NR_END;
}

unsigned long *lVector(long nl, long nh)
/* allocate an unsigned long Vector with subscript range v[nl..nh] */
{
	unsigned long *v;

	v=(unsigned long *)malloc((size_t) ((nh-nl+1+NR_END)*sizeof(long)));
	if (!v) nrerror("allocation failure in lVector()");
	return v-nl+NR_END;
}

double *dVector(long nl, long nh)
/* allocate a double Vector with subscript range v[nl..nh] */
{
	double *v;

	v=(double *)malloc((size_t) ((nh-nl+1+NR_END)*sizeof(double)));
	if (!v) nrerror("allocation failure in dVector()");
	return v-nl+NR_END;
}

double **matrix(long nrl, long nrh, long ncl, long nch)
/* allocate a double matrix with subscript range m[nrl..nrh][ncl..nch] */
{
	long i, nrow=nrh-nrl+1,ncol=nch-ncl+1;
	double **m;

	/* allocate pointers to rows */
	m=(double **) malloc((size_t)((nrow+NR_END)*sizeof(double*)));
	if (!m) nrerror("allocation failure 1 in matrix()");
	m += NR_END;
	m -= nrl;

	/* allocate rows and set pointers to them */
	m[nrl]=(double *) malloc((size_t)((nrow*ncol+NR_END)*sizeof(double)));
	if (!m[nrl]) nrerror("allocation failure 2 in matrix()");
	m[nrl] += NR_END;
	m[nrl] -= ncl;

	for(i=nrl+1;i<=nrh;i++) m[i]=m[i-1]+ncol;

	/* return pointer to array of pointers to rows */
	return m;
}

double **dmatrix(long nrl, long nrh, long ncl, long nch)
/* allocate a double matrix with subscript range m[nrl..nrh][ncl..nch] */
{
	long i, nrow=nrh-nrl+1,ncol=nch-ncl+1;
	double **m;

	/* allocate pointers to rows */
	m=(double **) malloc((size_t)((nrow+NR_END)*sizeof(double*)));
	if (!m) nrerror("allocation failure 1 in matrix()");
	m += NR_END;
	m -= nrl;

	/* allocate rows and set pointers to them */
	m[nrl]=(double *) malloc((size_t)((nrow*ncol+NR_END)*sizeof(double)));
	if (!m[nrl]) nrerror("allocation failure 2 in matrix()");
	m[nrl] += NR_END;
	m[nrl] -= ncl;

	for(i=nrl+1;i<=nrh;i++) m[i]=m[i-1]+ncol;

	/* return pointer to array of pointers to rows */
	return m;
}

int **imatrix(long nrl, long nrh, long ncl, long nch)
/* allocate a int matrix with subscript range m[nrl..nrh][ncl..nch] */
{
	long i, nrow=nrh-nrl+1,ncol=nch-ncl+1;
	int **m;

	/* allocate pointers to rows */
	m=(int **) malloc((size_t)((nrow+NR_END)*sizeof(int*)));
	if (!m) nrerror("allocation failure 1 in matrix()");
	m += NR_END;
	m -= nrl;


	/* allocate rows and set pointers to them */
	m[nrl]=(int *) malloc((size_t)((nrow*ncol+NR_END)*sizeof(int)));
	if (!m[nrl]) nrerror("allocation failure 2 in matrix()");
	m[nrl] += NR_END;
	m[nrl] -= ncl;

	for(i=nrl+1;i<=nrh;i++) m[i]=m[i-1]+ncol;

	/* return pointer to array of pointers to rows */
	return m;
}

double **submatrix(double **a, long oldrl, long oldrh, long oldcl, long oldch,
	long newrl, long newcl)
/* point a submatrix [newrl..][newcl..] to a[oldrl..oldrh][oldcl..oldch] */
{
	long i,j,nrow=oldrh-oldrl+1,ncol=oldcl-newcl;
	double **m;

	/* allocate array of pointers to rows */
	m=(double **) malloc((size_t) ((nrow+NR_END)*sizeof(double*)));
	if (!m) nrerror("allocation failure in submatrix()");
	m += NR_END;
	m -= newrl;

	/* set pointers to rows */
	for(i=oldrl,j=newrl;i<=oldrh;i++,j++) m[j]=a[i]+ncol;

	/* return pointer to array of pointers to rows */
	return m;
}

double **convert_dmatrix(double *a, long nrl, long nrh, long ncl, long nch)
/* allocate a double matrix m[nrl..nrh][ncl..nch] that points to the matrix
declared in the standard C manner as a[nrow][ncol], where nrow=nrh-nrl+1
and ncol=nch-ncl+1. The routine should be called with the address
&a[0][0] as the first argument. */
{
	long i,j,nrow=nrh-nrl+1,ncol=nch-ncl+1;
	double **m;

	/* allocate pointers to rows */
	m=(double **) malloc((size_t) ((nrow+NR_END)*sizeof(double*)));
	if (!m) nrerror("allocation failure in convert_dmatrix()");
	m += NR_END;
	m -= nrl;

	/* set pointers to rows */
	m[nrl]=a-ncl;
	for(i=1,j=nrl+1;i<nrow;i++,j++) m[j]=m[j-1]+ncol;
	/* return pointer to array of pointers to rows */
	return m;
}

double ***f3tensor(long nrl, long nrh, long ncl, long nch, long ndl, long ndh)
/* allocate a double 3tensor with range t[nrl..nrh][ncl..nch][ndl..ndh] */
{
	long i,j,nrow=nrh-nrl+1,ncol=nch-ncl+1,ndep=ndh-ndl+1;
	double ***t;

	/* allocate pointers to pointers to rows */
	t=(double ***) malloc((size_t)((nrow+NR_END)*sizeof(double**)));
	if (!t) nrerror("allocation failure 1 in f3tensor()");
	t += NR_END;
	t -= nrl;

	/* allocate pointers to rows and set pointers to them */
	t[nrl]=(double **) malloc((size_t)((nrow*ncol+NR_END)*sizeof(double*)));
	if (!t[nrl]) nrerror("allocation failure 2 in f3tensor()");
	t[nrl] += NR_END;
	t[nrl] -= ncl;

	/* allocate rows and set pointers to them */
	t[nrl][ncl]=(double *) malloc((size_t)((nrow*ncol*ndep+NR_END)*sizeof(double)));
	if (!t[nrl][ncl]) nrerror("allocation failure 3 in f3tensor()");
	t[nrl][ncl] += NR_END;
	t[nrl][ncl] -= ndl;

	for(j=ncl+1;j<=nch;j++) t[nrl][j]=t[nrl][j-1]+ndep;
	for(i=nrl+1;i<=nrh;i++) {
		t[i]=t[i-1]+ncol;
		t[i][ncl]=t[i-1][ncl]+ncol*ndep;
		for(j=ncl+1;j<=nch;j++) t[i][j]=t[i][j-1]+ndep;
	}

	/* return pointer to array of pointers to rows */
	return t;
}

void free_Vector(double *v, long nl, long nh)
/* free a double Vector allocated with Vector() */
{
	free((FREE_ARG) (v+nl-NR_END));
}

void free_iVector(int *v, long nl, long nh)
/* free an int Vector allocated with iVector() */
{
	free((FREE_ARG) (v+nl-NR_END));
}

void free_cVector(unsigned char *v, long nl, long nh)
/* free an unsigned char Vector allocated with cVector() */
{
	free((FREE_ARG) (v+nl-NR_END));
}

void free_lVector(unsigned long *v, long nl, long nh)
/* free an unsigned long Vector allocated with lVector() */
{
	free((FREE_ARG) (v+nl-NR_END));
}

void free_dVector(double *v, long nl, long nh)
/* free a double Vector allocated with dVector() */
{
	free((FREE_ARG) (v+nl-NR_END));
}

void free_matrix(double **m, long nrl, long nrh, long ncl, long nch)
/* free a double matrix allocated by matrix() */
{
	free((FREE_ARG) (m[nrl]+ncl-NR_END));
	free((FREE_ARG) (m+nrl-NR_END));
}

void free_dmatrix(double **m, long nrl, long nrh, long ncl, long nch)
/* free a double matrix allocated by dmatrix() */
{
	free((FREE_ARG) (m[nrl]+ncl-NR_END));
	free((FREE_ARG) (m+nrl-NR_END));
}

void free_imatrix(int **m, long nrl, long nrh, long ncl, long nch)
/* free an int matrix allocated by imatrix() */
{
	free((FREE_ARG) (m[nrl]+ncl-NR_END));
	free((FREE_ARG) (m+nrl-NR_END));
}

void free_submatrix(double **b, long nrl, long nrh, long ncl, long nch)
/* free a submatrix allocated by submatrix() */
{
	free((FREE_ARG) (b+nrl-NR_END));
}

void free_convert_dmatrix(double **b, long nrl, long nrh, long ncl, long nch)
/* free a matrix allocated by convert_dmatrix() */
{
	free((FREE_ARG) (b+nrl-NR_END));
}

void free_f3tensor(double ***t, long nrl, long nrh, long ncl, long nch,
	long ndl, long ndh)
/* free a double f3tensor allocated by f3tensor() */
{
	free((FREE_ARG) (t[nrl][ncl]+ndl-NR_END));
	free((FREE_ARG) (t[nrl]+ncl-NR_END));
	free((FREE_ARG) (t+nrl-NR_END));
}
