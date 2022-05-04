/*
    This software is Copyright by the Board of Trustees of Michigan
    State University (c) Copyright 2014.

    You may use this software under the terms of the GNU public license
    (GPL).  The terms of this license are described at:

     http://www.gnu.org/licenses/gpl.txt

     Authors:
             Ron Fox
             Jeromy Tompkins 
	     NSCL
	     Michigan State University
	     East Lansing, MI 48824-1321
*/


// Author:
//   Ron Fox
//   NSCL
//   Michigan State University
//   East Lansing, MI 48824-1321
//   mailto:fox@nscl.msu.edu
//
// Copyright 

#ifndef MYSPECTCLAPP_H  //Required for current class
#define MYSPECTCLAPP_H

#include "TclGrammerApp.h"

class CMySpecTclApp : public CTclGrammerApp {
 public:
  // Constructors:
  CMySpecTclApp(); //Default constructor alternative to compiler provided default constructor.
  ~CMySpecTclApp(); //Destructor - Delete any pointer data members that used new in constructors
  //Destructor should be virtual if and only if class contains at least one virtual function
  //Objects destroyed in the reverse order of the construction order
 private:
  CMySpecTclApp(const CMySpecTclApp& aCMySpecTclApp ); // Copy Constructor.

  // Operators:
  CMySpecTclApp& operator=(const CMySpecTclApp& aCMySpecTclApp);
  int operator==(const CMySpecTclApp& aCMySpecTclApp) const;

  // Class operations:
 public:
  virtual void BindTCLVariables(CTCLInterpreter& rInterp);
  virtual void SourceLimitScripts(CTCLInterpreter& rInterpreter);
  virtual void SetLimits();
  virtual void CreateHistogrammer();
  virtual void SelectDisplayer();
  virtual void SetupTestDataSource();
  virtual void CreateAnalyzer(CEventSink* pSink);
  virtual void SelectDecoder(CAnalyzer& rAnalyzer);
  virtual void CreateAnalysisPipeline(CAnalyzer& rAnalyzer);
  virtual void AddCommands(CTCLInterpreter& rInterp);
  virtual void SetupRunControl();
  virtual void SourceFunctionalScripts(CTCLInterpreter& rInterp);
  virtual int operator()();
};

#endif
