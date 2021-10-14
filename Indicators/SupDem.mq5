//+------------------------------------------------------------------+
//|                                                       SupDem.mq4 |
//|                      Copyright © 2008, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 0
input ENUM_TIMEFRAMES forced_tf = 0; // Timeframe of SD
input bool use_narrow_bands = false;
input bool kill_retouch = true;
input color TopColor = Maroon; // Resistance colour
input color BotColor = DarkBlue; // Support colour
input int Price_Width = 1; // Price sign width
input bool fillb=false; // Fill rectangles

double BuferUp[];
double BuferDn[];
int iPeriod = 13;
int Dev = 8;
int Step = 5;
datetime t1, t2;
double p1, p2;
string pair = _Symbol;
double point;
int digits;
ENUM_TIMEFRAMES tf;
string TAG;
datetime Time[];
double Low[], High[];

double up_cur, dn_cur;

int OnInit()
{
	SetIndexBuffer(1, BuferUp);
	PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
	PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
	SetIndexBuffer(0, BuferDn);
	PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
	PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
	if (forced_tf != 0) tf = forced_tf;
	else tf = Period();
	point = _Point;
	digits = _Digits;
	if (digits == 3 || digits == 5) point *= 10;
	TAG = "SupDem" + IntegerToString(tf);
	if (forced_tf < Period()) tf = 0;
	return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
	DeleteObjects();
	ChartRedraw();
	Comment("");
}

void DeleteObjects()
{
	int total = ObjectsTotal(0, 0);
	for (int i = total - 1; i >= 0; i--)
	{
		string obj_name = ObjectName(0, i);
		if (StringFind(obj_name, TAG) != -1)
			ObjectDelete(0, obj_name);
	}
}

int OnCalculate(const int rates_total,
	const int prev_calculated,
	const datetime &time[],
	const double &open[],
	const double &high[],
	const double &low[],
	const double &close[],
	const long &tick_volume[],
	const long &volume[],
	const int &spread[])
{

	ArraySetAsSeries(Low, true);
	ArraySetAsSeries(High, true);
	ArraySetAsSeries(Time, true);
	CopyTime(_Symbol, tf, 0, Bars(_Symbol, tf), Time);

	if (NewBar() == true)
	{
		CountZZ(BuferUp, BuferDn, iPeriod, Dev, Step);
		GetValid();
		Draw();
		ChartRedraw();
	}
	return(rates_total);
}

//
datetime iTime(string symbol, int tfi, int index)
{
	if (index < 0) return(-1);
	ENUM_TIMEFRAMES timeframe = TFMigrate(tfi);
	datetime Arr[];
	if (CopyTime(symbol, timeframe, index, 1, Arr) > 0)
		return(Arr[0]);
	else return(-1);
}
//

//
double iClose(string symbol, int tfi, int index)
{
	if (index < 0) return(-1);
	double Arr[];
	ENUM_TIMEFRAMES timeframe = TFMigrate(tfi);
	if (CopyClose(symbol, timeframe, index, 1, Arr) > 0)
		return(Arr[0]);
	else return(-1);
}
//

//
double iOpen(string symbol, int tfi, int index)
{
	if (index < 0) return(-1);
	double Arr[];
	ENUM_TIMEFRAMES timeframe = TFMigrate(tfi);
	if (CopyOpen(symbol, timeframe, index, 1, Arr) > 0)
		return(Arr[0]);
	else return(-1);
}
//

//
double iLow(string symbol, int tfi, int index)
{
	if (index < 0) return(-1);
	double Arr[];
	ENUM_TIMEFRAMES timeframe = TFMigrate(tfi);
	if (CopyLow(symbol, timeframe, index, 1, Arr) > 0)
		return(Arr[0]);
	else return(-1);
}
//

//
double iHigh(string symbol, int tfi, int index)
{
	if (index < 0) return(-1);
	double Arr[];
	ENUM_TIMEFRAMES timeframe = TFMigrate(tfi);
	if (CopyHigh(symbol, timeframe, index, 1, Arr) > 0)
		return(Arr[0]);
	else return(-1);
}
//

void Draw()
{
	int i;
	string s;
	DeleteObjects();
	for (i = 0; i < Bars(pair, tf); i++)
	{
		if (BuferDn[i] > 0.0)
		{
			t1 = iTime(pair, tf, i);
			t2 = Time[0];
			if (use_narrow_bands) p2 = MathMax(iClose(pair, tf, i), iOpen(pair, tf, i));
			else p2 = MathMin(iClose(pair, tf, i), iOpen(pair, tf, i));
			p2 = MathMax(p2, MathMax(iLow(pair, tf, i - 1), iLow(pair, tf, i + 1)));

			s = TAG + "UPAR" + IntegerToString(tf) + IntegerToString(i);
			DrawRightArrow(s, t2, p2, Price_Width, TopColor);

			s = TAG + "UPFILL" + IntegerToString(tf) + IntegerToString(i);
			DrawRectangle(s, t1, BuferDn[i], t2, p2, 1, STYLE_SOLID, TopColor, fillb);
		}

		if (BuferUp[i] > 0.0)
		{
			t1 = iTime(pair, tf, i);
			t2 = Time[0];
			if (use_narrow_bands) p2 = MathMin(iClose(pair, tf, i), iOpen(pair, tf, i));
			else p2 = MathMax(iClose(pair, tf, i), iOpen(pair, tf, i));
			if (i > 0) p2 = MathMin(p2, MathMin(iHigh(pair, tf, i + 1), iHigh(pair, tf, i - 1)));

			s = TAG + "DNAR" + IntegerToString(tf) + IntegerToString(i);
			DrawRightArrow(s, t2, p2, Price_Width, BotColor);

			s = TAG + "DNFILL" + IntegerToString(tf) + IntegerToString(i);
			DrawRectangle(s, t1, p2, t2, BuferUp[i], 1, STYLE_SOLID, BotColor, fillb);
		}
	}
}

bool NewBar() {

	static datetime LastTime = 0;

	if (iTime(pair, tf, 0) != LastTime) {
		LastTime = iTime(pair, tf, 0);
		return (true);
	}
	else
		return (false);
}

void CountZZ(double& ExtMapBuffer[], double& ExtMapBuffer2[], int ExtDepth, int ExtDeviation, int ExtBackstep)
{
	int    shift, back, lasthighpos, lastlowpos;
	double val, res;
	double curlow, curhigh, lasthigh = 0, lastlow = 0;
	int count = Bars(pair, tf) - ExtDepth;

	CopyLow(_Symbol, 0, 0, count, Low);
	CopyHigh(_Symbol, 0, 0, count, High);

	for (shift = count; shift >= 0; shift--)
	{
		val = iLow(pair, tf, ArrayMinimum(Low, 0, ExtDepth) + shift);
		if (val == lastlow) val = 0.0;
		else
		{
			lastlow = val;
			if ((iLow(pair, tf, shift) - val) > (ExtDeviation*_Point)) val = 0.0;
			else
			{
				for (back = 1; back <= ExtBackstep; back++)
				{
					res = ExtMapBuffer[shift + back];
					if ((res != 0) && (res > val)) ExtMapBuffer[shift + back] = 0.0;
				}
			}
		}
		
		ExtMapBuffer[shift] = val;
		//--- high
		val = iHigh(pair, tf, ArrayMaximum(High, 0, ExtDepth) + shift);

		if (val == lasthigh) val = 0.0;
		else
		{
			lasthigh = val;
			if ((val - iHigh(pair, tf, shift)) > (ExtDeviation*_Point)) val = 0.0;
			else
			{
				for (back = 1; back <= ExtBackstep; back++)
				{
					res = ExtMapBuffer2[shift + back];
					if ((res != 0) && (res < val)) ExtMapBuffer2[shift + back] = 0.0;
				}
			}
		}
		ExtMapBuffer2[shift] = val;
	}
	// final cutting
	lasthigh = -1; lasthighpos = -1;
	lastlow = -1;  lastlowpos = -1;

	for (shift = count; shift >= 0; shift--)
	{
		curlow = ExtMapBuffer[shift];
		curhigh = ExtMapBuffer2[shift];
		if ((curlow == 0) && (curhigh == 0)) continue;
		//---
		if (curhigh != 0)
		{
			if (lasthigh > 0)
			{
				if (lasthigh < curhigh) ExtMapBuffer2[lasthighpos] = 0;
				else ExtMapBuffer2[shift] = 0;
			}
			//---
			if (lasthigh < curhigh || lasthigh < 0)
			{
				lasthigh = curhigh;
				lasthighpos = shift;
			}
			lastlow = -1;
		}
		//----
		if (curlow != 0)
		{
			if (lastlow > 0)
			{
				if (lastlow > curlow) ExtMapBuffer[lastlowpos] = 0;
				else ExtMapBuffer[shift] = 0;
			}
			//---
			if ((curlow < lastlow) || (lastlow < 0))
			{
				lastlow = curlow;
				lastlowpos = shift;
			}
			lasthigh = -1;
		}
	}

	for (shift = Bars(pair, tf) - 1; shift >= 0; shift--)
	{
		if (shift >= count) ExtMapBuffer[shift] = 0.0;
		else
		{
			res = ExtMapBuffer2[shift];
			if (res != 0.0) ExtMapBuffer2[shift] = res;
		}
	}
}

void GetValid()
{
	up_cur = 0;
	int upbar = 0;
	dn_cur = 0;
	int dnbar = 0;
	double cur_hi = 0;
	double cur_lo = 0;
	double last_up = 0;
	double last_dn = 0;
	double low_dn = 0;
	double hi_up = 0;
	int i;
	for (i = 0; i < Bars(pair, tf); i++)
	{
		if (BuferUp[i] > 0)
		{
			up_cur = BuferUp[i];
			cur_lo = BuferUp[i];
			last_up = cur_lo;
			break;
		}
	}
	for (i = 0; i < Bars(pair, tf); i++)
	{
		if (BuferDn[i] > 0)
		{
			dn_cur = BuferDn[i];
			cur_hi = BuferDn[i];
			last_dn = cur_hi;
			break;
		}
	}

	for (i = 0; i < Bars(pair, tf); i++) // remove higher lows and lower highs
	{
		if (BuferDn[i] >= last_dn)
		{
			last_dn = BuferDn[i];
			dnbar = i;
		}
		else BuferDn[i] = 0.0;

		if (BuferDn[i] <= dn_cur && BuferUp[i] > 0.0) BuferDn[i] = 0.0;

		if (BuferUp[i] <= last_up && BuferUp[i] > 0)
		{
			last_up = BuferUp[i];
			upbar = i;
		}
		else BuferUp[i] = 0.0;

		if (BuferUp[i] > up_cur) BuferUp[i] = 0.0;

	}

	if (kill_retouch)
	{
		if (use_narrow_bands)
		{
			low_dn = MathMax(iOpen(pair, tf, dnbar), iClose(pair, tf, dnbar));
			hi_up = MathMin(iOpen(pair, tf, upbar), iClose(pair, tf, upbar));
		}
		else
		{
			low_dn = MathMin(iOpen(pair, tf, dnbar), iClose(pair, tf, dnbar));
			hi_up = MathMax(iOpen(pair, tf, upbar), iClose(pair, tf, upbar));
		}

		for (i = MathMax(upbar, dnbar); i >= 0; i--) // work back to zero and remove reentries into s/d
		{
			if (BuferDn[i] > low_dn && BuferDn[i] != last_dn) BuferDn[i] = 0.0;
			else if (use_narrow_bands && BuferDn[i] > 0)
			{
				low_dn = MathMax(iOpen(pair, tf, i), iClose(pair, tf, i));
				last_dn = BuferDn[i];
			}
			else if (BuferDn[i] > 0)
			{
				low_dn = MathMin(iOpen(pair, tf, i), iClose(pair, tf, i));
				last_dn = BuferDn[i];
			}

			if (BuferUp[i] <= hi_up && BuferUp[i] > 0 && BuferUp[i] != last_up) BuferUp[i] = 0.0;
			else if (use_narrow_bands && BuferUp[i] > 0)
			{
				hi_up = MathMin(iOpen(pair, tf, i), iClose(pair, tf, i));
				last_up = BuferUp[i];
			}
			else if (BuferUp[i] > 0)
			{
				hi_up = MathMax(iOpen(pair, tf, i), iClose(pair, tf, i));
				last_up = BuferUp[i];
			}
		}
	}
}

//+------------------------------------------------------------------+
ENUM_TIMEFRAMES TFMigrate(int tfi)
{
	switch (tfi)
	{
	case 0: return(PERIOD_CURRENT);
	case 1: return(PERIOD_M1);
	case 5: return(PERIOD_M5);
	case 15: return(PERIOD_M15);
	case 30: return(PERIOD_M30);
	case 60: return(PERIOD_H1);
	case 240: return(PERIOD_H4);
	case 1440: return(PERIOD_D1);
	case 10080: return(PERIOD_W1);
	case 43200: return(PERIOD_MN1);

	case 2: return(PERIOD_M2);
	case 3: return(PERIOD_M3);
	case 4: return(PERIOD_M4);
	case 6: return(PERIOD_M6);
	case 10: return(PERIOD_M10);
	case 12: return(PERIOD_M12);
	case 16385: return(PERIOD_H1);
	case 16386: return(PERIOD_H2);
	case 16387: return(PERIOD_H3);
	case 16388: return(PERIOD_H4);
	case 16390: return(PERIOD_H6);
	case 16392: return(PERIOD_H8);
	case 16396: return(PERIOD_H12);
	case 16408: return(PERIOD_D1);
	case 32769: return(PERIOD_W1);
	case 49153: return(PERIOD_MN1);
	default: return(PERIOD_CURRENT);
	}
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void DrawRectangle(const string name,
	const datetime time1,
	const double price1,
	const datetime time2,
	const double price2,
	const int width,
	const ENUM_LINE_STYLE style,
	const color colour,
	const bool fill = false)
{
	if (ObjectFind(0, name) < 0)
	{
		if (ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, price1, time2, price2))
		{
			ObjectSetInteger(0, name, OBJPROP_COLOR, colour);
			ObjectSetInteger(0, name, OBJPROP_BACK, true);
			ObjectSetInteger(0, name, OBJPROP_RAY, false);
			ObjectSetInteger(0, name, OBJPROP_STYLE, style);
			ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
			ObjectSetInteger(0, name, OBJPROP_FILL, fill);
		}
	}
	else
	{
		ObjectMove(0, name, 0, time1, price1);
		ObjectMove(0, name, 1, time2, price2);
	}
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void DrawRightArrow(const string name,
	const datetime time1,
	const double price1,
	const int width,
	const color colour)
{
	if (ObjectFind(0, name) < 0)
	{
		if (ObjectCreate(0, name, OBJ_ARROW_RIGHT_PRICE, 0, time1, price1))
		{
			ObjectSetInteger(0, name, OBJPROP_COLOR, colour);
			ObjectSetInteger(0, name, OBJPROP_BACK, true);
			ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
		}
	}
	else
	{
		ObjectMove(0, name, 0, time1, price1);
	}
}
//+------------------------------------------------------------------+