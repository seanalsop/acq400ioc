/* ------------------------------------------------------------------------- */
/*   Copyright (C) 2011 Peter Milne, D-TACQ Solutions Ltd
 *                      <Peter dot Milne at D hyphen TACQ dot com>

 http://www.d-tacq.com

 This program is free software; you can redistribute it and/or modify
 it under the terms of Version 2 of the GNU General Public License
 as published by the Free Software Foundation;

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.                */
/* ------------------------------------------------------------------------- */

/** @file AcqLoHostDescr.cpp DESCR
 * 
 *  Created on: May 3, 2012
 *      Author: pgm
 */

using namespace std;

#define acq200_debug acq_debug
#include "local.h"

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>


#include "alarm.h"
#include "cvtTable.h"
#include "dbDefs.h"
#include "dbAccess.h"
#include "dbScan.h"
#include "drvSup.h"
#include "recGbl.h"
#include "recSup.h"
#include "devSup.h"
#include "aiRecord.h"
#include "link.h"
#include "epicsExport.h"
#include "epicsThread.h"

#include "VFile.h"
#include "AcqLoHostDescr.h"

#include <string.h>

 AcqLoHostDescr::AcqLoHostDescr() : AcqHostDescr() {

}

 AcqLoHostDescr::~AcqLoHostDescr() {
	// TODO Auto-generated destructor stub
}
class ConcreteAcqLoHostDescr: public AcqLoHostDescr {
	char fname[80];
public:
	ConcreteAcqLoHostDescr(const char* _fname):
		AcqLoHostDescr()
	{
		strncpy(fname, _fname, sizeof(fname));
	}
	virtual bool setValue(int xx) {
		VFile vf(fname, "w");
		return vf.writeValue(xx);
	}
	virtual bool getInitValue(int& value) {
		VFile vf(fname, "r");
		return vf.readValue(value);
	}
};

AcqLoHostDescr* AcqLoHostDescr::create(const char* inp)
{
	char fname[80];
	return new ConcreteAcqLoHostDescr(makeName(inp, fname, 80));
}
