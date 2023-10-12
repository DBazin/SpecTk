#ifndef __SERVER_H
#define __SERVER_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string>
#include <vector>
#include <Analyzer.h>
#include <EventSink.h>
#include <Histogrammer.h>
#include <histotypes.h>
#include <Parameter.h>
#include <TCLProcessor.h>
#include <tcl.h>
#include <tk.h>
#include <tkDecls.h>
#include <TCLCommandPackage.h>
#include <TclGrammerApp.h>
#include <TCLResult.h>

/*--------------------------------------------------------------------------------------------*/

class CGet1DDataCommand : public CTCLProcessor
{

private:
	CHistogrammer		*m_pHistogrammer;

public:
// Constructor
	CGet1DDataCommand(CTCLInterpreter* pInterp,
	CHistogrammer* pHistogrammer) :
		CTCLProcessor("Get1DData", pInterp),
		m_pHistogrammer(pHistogrammer) {}
		
// Functionality
/*-------------------------------------------------------------
	CGet1DDataCommand
	
	Implements the command:
		Get1DData spectrum
	where:
	- spectrum is a 1D spectrum
	This command returns a list containing the data of a 1D spectrum.
---------------------------------------------------------------*/

int operator() (
	CTCLInterpreter& rInterp,
	CTCLResult& rResult,
	int argc,
	char* argv[]
	)
{
	Tcl_Interp		*interp = rInterp.getInterpreter();
	int					listArgc;
// patch difference in declared listArgv between 8.3 and 8.4
# if TCL_MINOR_VERSION==3
	char				**listArgv;
# endif
# if TCL_MINOR_VERSION==4
	const char				**listArgv;
# endif
	CSpectrum		*spectrumPtr;
	char				str[80];

// Parsing ...
// This command must have 1 arguments
	if (argc != 2) {
		rResult = "\
Usage:\n\
  Get1DData spectrum\n\
    where:\n\
    - spectrum is a 1D spectrum\n\
  Returns the spectrum data in binary format\n";
		return TCL_ERROR;
	}
	
// First argument should be a valid 1D spectrum
	spectrumPtr = m_pHistogrammer->FindSpectrum(argv[1]);
	if(spectrumPtr == (CSpectrum*)kpNULL) {
		sprintf(str, "Spectrum %s doesn't exist!", argv[1]);
		rResult = str;
		return TCL_ERROR;
	}
	if (spectrumPtr->Dimensionality() != 1) {
		sprintf(str, "Spectrum %s is not 1D!", argv[1]);
		rResult = str;
		return TCL_ERROR;
	}
	UInt_t		nx = spectrumPtr->Dimension(0);
	DataType_t	dt = spectrumPtr->StorageType();
	UInt_t		nz = 0;
	UChar_t*	pstorage = (UChar_t*)spectrumPtr->getStorage();
	UShort_t*	psWord;
	ULong_t*	psLong;
	if (dt == keWord) {
		nz = 2;
		psWord = (UShort_t*)pstorage;
	}
	if (dt == keLong) {
		nz = 4;
		psLong = (ULong_t*)pstorage;
	}
	if (nz == 0) {
		sprintf(str, "Spectrum %s has invalid data type", argv[1]);
		rResult = str;
		return TCL_ERROR;
	}
	
	unsigned char	*data;
	Tcl_Obj			*objPtr;

	objPtr = Tcl_GetObjResult(interp);
// Two possible modes depending on how many bins are != 0:
//		- mode=0: list of all bins
// 	- mode=1: list of non-zero bins followed by list of their values
	ULong_t		nonzero = 0;
	ULong_t		nbytes = nz * nx;
	if (dt == keWord) {for (int x=0; x<nx; x++) if (psWord[x] != 0) nonzero++;}
	if (dt == keLong) {for (int x=0; x<nx; x++) if (psLong[x] != 0) nonzero++;}
	ULong_t		zbytes = (nz+2) * nonzero;
// if there are less bytes using bins rather than indexed
	if (nbytes < zbytes) {
		Tcl_SetByteArrayLength(objPtr, nbytes+1);
		data = Tcl_GetByteArrayFromObj(objPtr, NULL);
		data[0] = 0; // mode=0
// Loop on channels to fill up string
		if (dt == keWord) {
			for (int x=0, i=1; x<nx; x++, i+=2) {
				data[i] = (char)psWord[x]&0xFF;
				data[i+1] = (char)(psWord[x]>>8);
			}
		}
		if (dt == keLong) {
			for (int x=0, i=1; x<nx; x++, i+=4) {
				data[i] = (char)psLong[x]&0xFF;
				data[i+1] = (char)(psLong[x]>>8);
				data[i+2] = (char)(psLong[x]>>16);
				data[i+3] = (char)(psLong[x]>>24);
			}
		}
// else there are less indexed bytes than bins
	} else {
		Tcl_SetByteArrayLength(objPtr, zbytes+5);
		data = Tcl_GetByteArrayFromObj(objPtr, NULL);
		data[0] = 1; // mode=1
		data[1] = (char)nonzero&0xFF;
		data[2] = (char)(nonzero>>8);
		data[3] = (char)(nonzero>>16);
		data[4] = (char)(nonzero>>24);
// Loop on channels to fill up string
		if (dt == keWord) {
			for (int x=0, i=5, j=5+nonzero*2; x<nx; x++) {
				if (psWord[x] != 0) {
					data[i] = (char)x&0xFF;
					data[i+1] = (char)(x>>8);
					data[j] = (char)psWord[x]&0xFF;
					data[j+1] = (char)(psWord[x]>>8);
					i += 2;
					j += 2;
				}
			}
		}
		if (dt == keLong) {
			for (int x=0, i=5, j=5+nonzero*2; x<nx; x++) {
				if (psLong[x] != 0) {
					data[i] = (char)x&0xFF;
					data[i+1] = (char)(x>>8);
					data[j] = (char)psLong[x]&0xFF;
					data[j+1] = (char)(psLong[x]>>8);
					data[j+2] = (char)(psLong[x]>>16);
					data[j+3] = (char)(psLong[x]>>24);
					i += 2;
					j += 4;
				}
			}
		}
	}

	return TCL_OK;
}

};

/*--------------------------------------------------------------------------------------------*/

class CGet2DDataCommand : public CTCLProcessor
{

private:
	CHistogrammer		*m_pHistogrammer;

public:
// Constructor
	CGet2DDataCommand(CTCLInterpreter* pInterp,
	CHistogrammer* pHistogrammer) :
		CTCLProcessor("Get2DData", pInterp),
		m_pHistogrammer(pHistogrammer) {}
		
// Functionality
/*-------------------------------------------------------------
	CGet2DDataCommand
	
	Implements the command:
		Get2DData spectrum
	where:
	- spectrum is a 2D spectrum
	This command returns a list containing the data of a 1D spectrum.
---------------------------------------------------------------*/

int operator() (
	CTCLInterpreter& rInterp,
	CTCLResult& rResult,
	int argc,
	char* argv[]
	)
{
	Tcl_Interp		*interp = rInterp.getInterpreter();
	int					listArgc;
// patch difference in declared listArgv between 8.3 and 8.4
# if TCL_MINOR_VERSION==3
	char				**listArgv;
# endif
# if TCL_MINOR_VERSION==4
	const char				**listArgv;
# endif
	CSpectrum		*spectrumPtr;
	char				str[80];

// Parsing ...
// This command must have 1 arguments
	if (argc != 2) {
		rResult = "\
Usage:\n\
  Get2DData spectrum\n\
    where:\n\
    - spectrum is a 2D spectrum\n\
  Returns the spectrum data in binary format\n";
		return TCL_ERROR;
	}
	
// First argument should be a valid 2D spectrum
	spectrumPtr = m_pHistogrammer->FindSpectrum(argv[1]);
	if(spectrumPtr == (CSpectrum*)kpNULL) {
		sprintf(str, "Spectrum %s doesn't exist!", argv[1]);
		rResult = str;
		return TCL_ERROR;
	}
	if (spectrumPtr->Dimensionality() != 2) {
		sprintf(str, "Spectrum %s is not 2D!", argv[1]);
		rResult = str;
		return TCL_ERROR;
	}
	UInt_t		nx = spectrumPtr->Dimension(0);
	UInt_t		ny = spectrumPtr->Dimension(1);
	DataType_t	dt = spectrumPtr->StorageType();
	UInt_t		nz = 0;
	UChar_t*	pstorage = (UChar_t*)spectrumPtr->getStorage();
	UChar_t*	psByte;
	UShort_t*	psWord;
	if (dt == keByte) {
		nz = 1;
		psByte = (UChar_t*)pstorage;
	}
	if (dt == keWord) {
		nz = 2;
		psWord = (UShort_t*)pstorage;
	}
	if (nz == 0) {
		sprintf(str, "Spectrum %s has invalid data type", argv[1]);
		rResult = str;
		return TCL_ERROR;
	}
	
	unsigned char	*data;
	Tcl_Obj			*objPtr;
	int					ynx, i, j, k;

	objPtr = Tcl_GetObjResult(interp);
// Two possible modes depending on how many bins are != 0:
//		- mode=0: list of all bins
// 	- mode=1: list of non-zero bins followed by list of their values
	ULong_t		nonzero = 0;
	ULong_t		nbytes = nz * nx * ny;
	if (dt == keByte) {
		for (int y=0; y<ny; y++) {
			ynx = y * nx;
			for (int x=0; x<nx; x++) if (psByte[ynx + x] != 0) nonzero++;
		}
	}
	if (dt == keWord) {
		for (int y=0; y<ny; y++) {
			ynx = y * nx;
			for (int x=0; x<nx; x++) if (psWord[ynx + x] != 0) nonzero++;
		}
	}
	ULong_t		zbytes = (nz+4) * nonzero;
// if there are less bytes using bins rather than indexed
	if (nbytes < zbytes) {
		Tcl_SetByteArrayLength(objPtr, nbytes+1);
		data = Tcl_GetByteArrayFromObj(objPtr, NULL);
		data[0] = 0; // mode=0
// Loop on channels to fill up string
		if (dt == keByte) {
			i = 1;
			for (int y=0; y<ny; y++) {
				ynx = y * nx;
				for (int x=0; x<nx; x++) {
					data[i] = (char)psByte[x + ynx];
					i++;
				}
			}
		}
		if (dt == keWord) {
			i = 1;
			for (int y=0; y<ny; y++) {
				ynx = y * nx;
				for (int x=0; x<nx; x++) {
					data[i] = (char)psWord[x + ynx]&0xFF;
					data[i+1] = (char)(psWord[x + ynx]>>8);
					i += 2;
				}
			}
		}
// else there are less indexed bytes than bins
	} else {
		Tcl_SetByteArrayLength(objPtr, zbytes+5);
		data = Tcl_GetByteArrayFromObj(objPtr, NULL);
		data[0] = 1; // mode=1
		data[1] = (char)nonzero&0xFF;
		data[2] = (char)(nonzero>>8);
		data[3] = (char)(nonzero>>16);
		data[4] = (char)(nonzero>>24);
// Loop on channels to fill up string
		if (dt == keByte) {
			i = 5;
			j = 5+nonzero*2;
			k = 5+nonzero*4;
			for (int y=0; y<ny; y++) {
				ynx = y * nx;
				for (int x=0; x<nx; x++) {
					if (psByte[x + ynx] != 0) {
						data[i] = (char)x&0xFF;
						data[i+1] = (char)(x>>8);
						data[j] = (char)y&0xFF;
						data[j+1] = (char)(y>>8);
						data[k] = (char)psByte[x + ynx];
						i += 2;
						j += 2;
						k++;
					}
				}
			}
		}
		if (dt == keWord) {
			i = 5;
			j = 5+nonzero*2;
			k = 5+nonzero*4;
			for (int y=0; y<ny; y++) {
				ynx = y * nx;
				for (int x=0; x<nx; x++) {
					if (psWord[x + ynx] != 0) {
						data[i] = (char)x&0xFF;
						data[i+1] = (char)(x>>8);
						data[j] = (char)y&0xFF;
						data[j+1] = (char)(y>>8);
						data[k] = (char)psWord[x + ynx]&0xFF;
						data[k+1] = (char)(psWord[x + ynx]>>8);
						i += 2;
						j += 2;
						k += 2;
					}
				}
			}
		}
	}

	return TCL_OK;
}

};


void AddServerCommands(CTclGrammerApp *theApp, CTCLInterpreter& rInterp)
{
	CHistogrammer* ourHistogrammer = (CHistogrammer*)theApp->getHistogrammer();

	CGet1DDataCommand* Get1DDataCommand;
	Get1DDataCommand = new CGet1DDataCommand(&rInterp, ourHistogrammer);
	Get1DDataCommand->Register();

	CGet2DDataCommand* Get2DDataCommand;
	Get2DDataCommand = new CGet2DDataCommand(&rInterp, ourHistogrammer);
	Get2DDataCommand->Register();
}


#endif
