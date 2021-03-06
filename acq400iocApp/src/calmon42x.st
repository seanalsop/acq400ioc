
// seq calmon "uut=acq1001_064,site=1"
// seq calmon "uut=acq1001_064,site=2"
// dbpr acq1001_064:1:ADC_MODE
// dbpr acq1001_064:1:AI:CH:01 2
// acq1001_064:1:AI:CH:01
// acq1001_064:1:AI:TW:01:V
// acq1001_064:1:AI:WF:01:V

program calmon42x
option +r;

int adc_cal_mode; assign adc_cal_mode to "{uut}:1:ADC_CAL";
monitor adc_cal_mode;
int adc_cal_mode0;


float ext_eslo[33]; 	assign ext_eslo to "{uut}:{site}:AI:CAL:ESLO";
float ext_eoff[33]; 	assign ext_eoff to "{uut}:{site}:AI:CAL:EOFF";

float eslo[33];		assign eslo to {};	// index from 1
float eoff[33]; 	assign eoff to {};

int has_ch_gains;	assign has_ch_gains to "{uut}:{site}:HAS_CH_GAINS";

int gain_changes;	assign gain_changes to "";
int gain_changes0;

int gains[33];		assign gains to {};	/* "${UUT}:${SITE}:GAIN:${CH}" */

char* doc;
char fname[80];
char* uut;
char* site = "1";		// default site 1, should override 
int ch;
int nchan;
char pvname[80];
char pvfield[100];
%%extern void* acq400_openDoc(const char* docfile, int* nchan);
%%extern int acq400_getChannel(void *prv, int ch, const char* sw, float* eslo, float* eoff, int nocal);

%{
static char* getKey(int gain) 
{ 
	static char key[8];
	
	snprintf(key, 8, "%d", gain);
	
	return key; 
}
}%

ss calmon {
	state init {
		when() {
			printf("calmon R1000 site:%s\n", site);			
			pvGet(adc_cal_mode); adc_cal_mode0 = adc_cal_mode;
			pvGet(has_ch_gains);
			uut = macValueGet("uut"); 
			if (macValueGet("site") != 0){
				site = macValueGet("site");
			}
			sprintf(fname, "/dev/sites/%s/caldef.xml",  site);			
			doc = acq400_openDoc(fname, &nchan);
		} state init2
	}
	state init2 {
		when(doc == 0) {
			printf("ERROR failed to read caldef.xml\n");
		} state error
		
		when(doc != 0){
			for (ch = 1; ch <= nchan; ++ch){				
				snprintf(pvname, 80, "%s:%s:AI:CH:%02d", uut, site, ch);						
				snprintf(pvfield, 100, "%s.%s", pvname, "ESLO");
				pvAssign(eslo[ch], pvfield);
				if (ch==1) printf("assign %s\n",pvfield);
				
				snprintf(pvfield, 100, "%s.%s", pvname, "EOFF");
				pvAssign(eoff[ch], pvfield);
				if (ch==1) printf("assign %s\n",pvfield);
				
				if (has_ch_gains){
					snprintf(pvname, 80, "%s:%s:GAIN:%02d.RVAL", uut, site, ch);
					pvAssign(gains[ch], pvname);
				}
			}
			if (has_ch_gains){
				snprintf(pvname, 80, "%s:%s:GAIN_CHANGES", uut, site);
				pvAssign(gain_changes, pvname);			
				pvMonitor(gain_changes);
			}
		} state make_change		
	}
	
	state error {	
		when(delay(1000)) {
		
		} state error
	}
	
	state make_change {
		when() {
			pvGet(adc_cal_mode);
			if (adc_cal_mode != 0){
				printf("make_change site=%s %s\n", site, adc_cal_mode==1? "caldef": "calibrated");
				for (ch = 1; ch <= nchan; ++ch){
					if (has_ch_gains){
						pvGet(gains[ch]);
					}		
					if (acq400_getChannel(doc, ch, getKey(gains[ch]), 
								&eslo[ch], &eoff[ch], adc_cal_mode==1) == 1){
						if (ch==1){
							printf("site:%s g:%d ch:%2d eslo:%.6e eoff:%.6e\n", 
										site, gains[ch], ch, eslo[ch], eoff[ch]);
						}
						pvPut(eslo[ch]);
                                                pvPut(eoff[ch]);
                                                
                                                ext_eslo[ch] = eslo[ch];
                                                ext_eoff[ch] = eoff[ch];
					}else{
						printf("ERROR return from acq400_getChannel()\n");
					}
				}
				pvPut(ext_eslo);
				pvPut(ext_eoff);
			}else{
				printf("make_change: STUB\n");
			}
		} state wait_change
	}
	
	state wait_change {
		when(adc_cal_mode != adc_cal_mode0 || gain_changes != gain_changes0){
			if (adc_cal_mode != adc_cal_mode0){
				printf("cal mode changed=>%d\n", adc_cal_mode);
				adc_cal_mode0 = adc_cal_mode;
			}
			if (gain_changes != gain_changes0){
				printf("gain change %d\n", gain_changes);
				gain_changes0 = gain_changes;
			}		 			
		} state make_change
	}
}