// This file contains portions of code released by Microsoft under the MIT license as part
// of an open-sourcing initiative in 2014 of the C# core libraries.
// The original source was submitted to https://github.com/Microsoft/referencesource

namespace System.Globalization {
    //
    // N.B.:
    // A lot of this code is directly from DateTime.cs.  If you update that class,
    // update this one as well.
    // However, we still need these duplicated code because we will add era support
    // in this class.
    //
    //

    using System.Threading;
    using System;
    using System.Globalization;
    using System.Diagnostics.Contracts;

	public enum GregorianCalendarTypes
	{
	    Localized = Calendar.[Friend]CAL_GREGORIAN,
	    USEnglish = Calendar.[Friend]CAL_GREGORIAN_US,
	    MiddleEastFrench = Calendar.[Friend]CAL_GREGORIAN_ME_FRENCH,
	    Arabic = Calendar.[Friend]CAL_GREGORIAN_ARABIC,
	    TransliteratedEnglish = Calendar.[Friend]CAL_GREGORIAN_XLIT_ENGLISH,
	    TransliteratedFrench = Calendar.[Friend]CAL_GREGORIAN_XLIT_FRENCH,
	}

    // This calendar recognizes two era values:
    // 0 CurrentEra (AD)
    // 1 BeforeCurrentEra (BC)

    public class GregorianCalendar : Calendar
    {
        /*
            A.D. = anno Domini
         */

        public const int ADEra = 1;


        const int DatePartYear = 0;
        const int DatePartDayOfYear = 1;
        const int DatePartMonth = 2;
        const int DatePartDay = 3;

        //
        // This is the max Gregorian year can be represented by DateTime class.  The limitation
        // is derived from DateTime class.
        //
        const int MaxYear = 9999;

        GregorianCalendarTypes m_type;

        static readonly int[] DaysToMonth365 = new int[]
        {
            0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365
        } ~ delete _;

        static readonly int[] DaysToMonth366 = new int[]
        {
            0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366
        } ~ delete _;

        private static volatile Calendar s_defaultInstance;


#region Serialization 
        /*private void OnDeserialized(StreamingContext ctx)
        {
            if (m_type < GregorianCalendarTypes.Localized || 
                m_type > GregorianCalendarTypes.TransliteratedFrench) 
            {
                throw new SerializationException(
                            String.Format(
                                CultureInfo.CurrentCulture, 
                                Environment.GetResourceString(
                                                "Serialization_MemberOutOfRange"),
                                                "type", 
                                                "GregorianCalendar"));
            }
        }*/
#endregion Serialization

        public override DateTime MinSupportedDateTime
        {
            get
            {
                return (DateTime.MinValue);
            }
        }

        public override DateTime MaxSupportedDateTime
        {
            get
            {
                return (DateTime.MaxValue);
            }
        }

        public override CalendarAlgorithmType AlgorithmType
        {
            get
            {
                return CalendarAlgorithmType.SolarCalendar;
            }
        }

        /*=================================GetDefaultInstance==========================
        **Action: Internal method to provide a default intance of GregorianCalendar.  Used by NLS+ implementation
        **       and other calendars.
        **Returns:
        **Arguments:
        **Exceptions:
        ============================================================================*/

        static Calendar GetDefaultInstance() {
            if (s_defaultInstance == null) {
                s_defaultInstance = new GregorianCalendar();
            }
            return (s_defaultInstance);
        }

        // Construct an instance of gregorian calendar.

        public this() :
            this(GregorianCalendarTypes.Localized)
		{
        }


        public this(GregorianCalendarTypes type) {
            if ((int)type < (int)GregorianCalendarTypes.Localized || (int)type > (int)GregorianCalendarTypes.TransliteratedFrench) {
                /*throw new ArgumentOutOfRangeException(
                            "type",
                            Environment.GetResourceString("ArgumentOutOfRange_Range",
                    GregorianCalendarTypes.Localized, GregorianCalendarTypes.TransliteratedFrench));*/
				Runtime.FatalError();
            }
            Contract.EndContractBlock();
            this.m_type = type;
        }

        public virtual GregorianCalendarTypes CalendarType {
            get {
                return (m_type);
            }

            set {
                this.[Friend]VerifyWritable();

                switch (value)
				{
                case GregorianCalendarTypes.Localized:
                case GregorianCalendarTypes.USEnglish:
                case GregorianCalendarTypes.MiddleEastFrench:
                case GregorianCalendarTypes.Arabic:
                case GregorianCalendarTypes.TransliteratedEnglish:
                case GregorianCalendarTypes.TransliteratedFrench:
                    m_type = value;
                    break;

                default:
				Runtime.FatalError();
                        //throw new ArgumentOutOfRangeException("m_type", Environment.GetResourceString("ArgumentOutOfRange_Enum"));
                }
            }
        }

        protected override int ID {
            get {
                // By returning different ID for different variations of GregorianCalendar,
                // we can support the Transliterated Gregorian calendar.
                // DateTimeFormatInfo will use this ID to get formatting information about
                // the calendar.
                return ((int)m_type);
            }
        }

        // Returns a given date part of this DateTime. This method is used
        // to compute the year, day-of-year, month, or day part.
        protected virtual int GetDatePart(int64 ticks, int part)
        {
            // n = number of days since 1/1/0001
            int n = (int)(ticks / TicksPerDay);
            // y400 = number of whole 400-year periods since 1/1/0001
            int y400 = n / DaysPer400Years;
            // n = day number within 400-year period
            n -= y400 * DaysPer400Years;
            // y100 = number of whole 100-year periods within 400-year period
            int y100 = n / DaysPer100Years;
            // Last 100-year period has an extra day, so decrement result if 4
            if (y100 == 4) y100 = 3;
            // n = day number within 100-year period
            n -= y100 * DaysPer100Years;
            // y4 = number of whole 4-year periods within 100-year period
            int y4 = n / DaysPer4Years;
            // n = day number within 4-year period
            n -= y4 * DaysPer4Years;
            // y1 = number of whole years within 4-year period
            int y1 = n / DaysPerYear;
            // Last year has an extra day, so decrement result if 4
            if (y1 == 4) y1 = 3;
            // If year was requested, compute and return it
            if (part == DatePartYear)
            {
                return (y400 * 400 + y100 * 100 + y4 * 4 + y1 + 1);
            }
            // n = day number within year
            n -= y1 * DaysPerYear;
            // If day-of-year was requested, return it
            if (part == DatePartDayOfYear)
            {
                return (n + 1);
            }
            // Leap year calculation looks different from IsLeapYear since y1, y4,
            // and y100 are relative to year 1, not year 0
            bool leapYear = (y1 == 3 && (y4 != 24 || y100 == 3));
            int[] days = leapYear? DaysToMonth366: DaysToMonth365;
            // All months have less than 32 days, so n >> 5 is a good conservative
            // estimate for the month
            int m = n >> 5 + 1;
            // m = 1-based month number
            while (n >= days[m]) m++;
            // If month was requested, return it
            if (part == DatePartMonth) return (m);
            // Return 1-based day-of-month
            return (n - days[m - 1] + 1);
        }

        /*=================================GetAbsoluteDate==========================
        **Action: Gets the absolute date for the given Gregorian date.  The absolute date means
        **       the number of days from January 1st, 1 A.D.
        **Returns:  the absolute date
        **Arguments:
        **      year    the Gregorian year
        **      month   the Gregorian month
        **      day     the day
        **Exceptions:
        **      ArgumentOutOfRangException  if year, month, day value is valid.
        **Note:
        **      This is an internal method used by DateToTicks() and the calculations of Hijri and Hebrew calendars.
        **      Number of Days in Prior Years (both common and leap years) +
        **      Number of Days in Prior Months of Current Year +
        **      Number of Days in Current Month
        **
        ============================================================================*/

        static Result<int64> GetAbsoluteDate(int year, int month, int day) {
            if (year >= 1 && year <= MaxYear && month >= 1 && month <= 12)
            {
                int[] days = ((year % 4 == 0 && (year % 100 != 0 || year % 400 == 0))) ? DaysToMonth366: DaysToMonth365;
                if (day >= 1 && (day <= days[month] - days[month - 1])) {
                    int y = year - 1;
                    int absoluteDate = y * 365 + y / 4 - y / 100 + y / 400 + days[month - 1] + day - 1;
                    return (absoluteDate);
                }
            }
            //throw new ArgumentOutOfRangeException(null, Environment.GetResourceString("ArgumentOutOfRange_BadYearMonthDay"));
			return .Err;
        }

        // Returns the tick count corresponding to the given year, month, and day.
        // Will check the if the parameters are valid.
        protected virtual Result<int64> DateToTicks(int year, int month, int day) {
            return (Try!(GetAbsoluteDate(year, month,  day)) * TicksPerDay);
        }

        // Returns the DateTime resulting from adding the given number of
        // months to the specified DateTime. The result is computed by incrementing
        // (or decrementing) the year and month parts of the specified DateTime by
        // value months, and, if required, adjusting the day part of the
        // resulting date downwards to the last day of the resulting month in the
        // resulting year. The time-of-day part of the result is the same as the
        // time-of-day part of the specified DateTime.
        //
        // In more precise terms, considering the specified DateTime to be of the
        // form y / m / d + t, where y is the
        // year, m is the month, d is the day, and t is the
        // time-of-day, the result is y1 / m1 / d1 + t,
        // where y1 and m1 are computed by adding value months
        // to y and m, and d1 is the largest value less than
        // or equal to d that denotes a valid day in month m1 of year
        // y1.
        //

        public override Result<DateTime> AddMonths(DateTime time, int months)
        {
            if (months < -120000 || months > 120000) {
                /*throw new ArgumentOutOfRangeException(
                            "months",
                            String.Format(
                                CultureInfo.CurrentCulture,
                                Environment.GetResourceString("ArgumentOutOfRange_Range"),
                                -120000,
                                120000));*/
				return .Err;
            }
            Contract.EndContractBlock();
            int y = GetDatePart(time.Ticks, DatePartYear);
            int m = GetDatePart(time.Ticks, DatePartMonth);
            int d = GetDatePart(time.Ticks, DatePartDay);
            int i = m - 1 + months;
            if (i >= 0)
            {
                m = i % 12 + 1;
                y = y + i / 12;
            }
            else
            {
                m = 12 + (i + 1) % 12;
                y = y + (i - 11) / 12;
            }
            int[] daysArray = (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? DaysToMonth366: DaysToMonth365;
            int days = (daysArray[m] - daysArray[m - 1]);

            if (d > days)
            {
                d = days;
            }
            int64 ticks = Try!(DateToTicks(y, m, d)) + time.Ticks % TicksPerDay;
            Try!(Calendar.[Friend]CheckAddResult(ticks, MinSupportedDateTime, MaxSupportedDateTime));

            return (DateTime(ticks));
        }


        // Returns the DateTime resulting from adding the given number of
        // years to the specified DateTime. The result is computed by incrementing
        // (or decrementing) the year part of the specified DateTime by value
        // years. If the month and day of the specified DateTime is 2/29, and if the
        // resulting year is not a leap year, the month and day of the resulting
        // DateTime becomes 2/28. Otherwise, the month, day, and time-of-day
        // parts of the result are the same as those of the specified DateTime.
        //

        public override Result<DateTime> AddYears(DateTime time, int years)
        {
            return (AddMonths(time, years * 12));
        }

        // Returns the day-of-month part of the specified DateTime. The returned
        // value is an integer between 1 and 31.
        //

        public override Result<int> GetDayOfMonth(DateTime time)
        {
            return (GetDatePart(time.Ticks, DatePartDay));
        }

        // Returns the day-of-week part of the specified DateTime. The returned value
        // is an integer between 0 and 6, where 0 indicates Sunday, 1 indicates
        // Monday, 2 indicates Tuesday, 3 indicates Wednesday, 4 indicates
        // Thursday, 5 indicates Friday, and 6 indicates Saturday.
        //

        public override Result<DayOfWeek> GetDayOfWeek(DateTime time)
        {
            return ((DayOfWeek)((int)(time.Ticks / TicksPerDay + 1) % 7));
        }

        // Returns the day-of-year part of the specified DateTime. The returned value
        // is an integer between 1 and 366.
        //

        public override Result<int> GetDayOfYear(DateTime time)
        {
            return (GetDatePart(time.Ticks, DatePartDayOfYear));
        }

        // Returns the number of days in the month given by the year and
        // month arguments.
        //

        public override Result<int> GetDaysInMonth(int year, int month, int era)
		{
            if (era == CurrentEra || era == ADEra) {
                if (year < 1 || year > MaxYear) {
                    /*throw new ArgumentOutOfRangeException("year", Environment.GetResourceString("ArgumentOutOfRange_Range",
                        1, MaxYear));*/
					return .Err;
                }
                if (month < 1 || month > 12) {
                    //throw new ArgumentOutOfRangeException("month", Environment.GetResourceString("ArgumentOutOfRange_Month"));
					return .Err;
                }
                int[] days = ((year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? DaysToMonth366: DaysToMonth365);
                return (days[month] - days[month - 1]);
            }
            //throw new ArgumentOutOfRangeException("era", Environment.GetResourceString("ArgumentOutOfRange_InvalidEraValue"));
			return .Err;
        }

        // Returns the number of days in the year given by the year argument for the current era.
        //

        public override Result<int> GetDaysInYear(int year, int era)
        {
            if (era == CurrentEra || era == ADEra) {
                if (year >= 1 && year <= MaxYear) {
                    return ((year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 366:365);
                }
                /*throw new ArgumentOutOfRangeException(
                            "year",
                            String.Format(
                                CultureInfo.CurrentCulture,
                                Environment.GetResourceString("ArgumentOutOfRange_Range"),
                                1,
                                MaxYear));*/
				return .Err;
            }
            //throw new ArgumentOutOfRangeException("era", Environment.GetResourceString("ArgumentOutOfRange_InvalidEraValue"));
			return .Err;
        }

        // Returns the era for the specified DateTime value.

        public override Result<int> GetEra(DateTime time)
        {
            return (ADEra);
        }


        public override int[] Eras
		{
            get
			{
                return (new int[] {ADEra} );
            }
        }


        // Returns the month part of the specified DateTime. The returned value is an
        // integer between 1 and 12.
        //

        public override Result<int> GetMonth(DateTime time)
        {
            return (GetDatePart(time.Ticks, DatePartMonth));
        }

        // Returns the number of months in the specified year and era.

        public override Result<int> GetMonthsInYear(int year, int era)
        {
            if (era == CurrentEra || era == ADEra) {
                if (year >= 1 && year <= MaxYear)
                {
                    return (12);
                }
                /*throw new ArgumentOutOfRangeException(
                            "year",
                            String.Format(
                                CultureInfo.CurrentCulture,
                                Environment.GetResourceString("ArgumentOutOfRange_Range"),
                                1,
                                MaxYear));*/
				return .Err;
            }
            //throw new ArgumentOutOfRangeException("era", Environment.GetResourceString("ArgumentOutOfRange_InvalidEraValue"));
			return .Err;
        }

        // Returns the year part of the specified DateTime. The returned value is an
        // integer between 1 and 9999.
        //

        public override Result<int> GetYear(DateTime time)
        {
            return (GetDatePart(time.Ticks, DatePartYear));
        }

        // Checks whether a given day in the specified era is a leap day. This method returns true if
        // the date is a leap day, or false if not.
        //

        public override Result<bool> IsLeapDay(int year, int month, int day, int era)
        {
            if (month < 1 || month > 12) {
                /*throw new ArgumentOutOfRangeException("month", Environment.GetResourceString("ArgumentOutOfRange_Range",
                    1, 12));*/
				return .Err;
            }
            Contract.EndContractBlock();

            if (era != CurrentEra && era != ADEra)
            {
                //throw new ArgumentOutOfRangeException("era", Environment.GetResourceString("ArgumentOutOfRange_InvalidEraValue"));
				return .Err;
            }
            if (year < 1 || year > MaxYear) {
                /*throw new ArgumentOutOfRangeException(
                                "year",
                                Environment.GetResourceString("ArgumentOutOfRange_Range", 1, MaxYear));*/
				return .Err;
            }

            if (day < 1 || day > Try!(GetDaysInMonth(year, month))) {
                /*throw new ArgumentOutOfRangeException("day", Environment.GetResourceString("ArgumentOutOfRange_Range",
                    1, GetDaysInMonth(year, month)));*/
				return .Err;
            }
            if (!Try!(IsLeapYear(year))) {
                return (false);
            }
            if (month == 2 && day == 29) {
                return (true);
            }
            return (false);
        }

        // Returns  the leap month in a calendar year of the specified era. This method returns 0
        // if this calendar does not have leap month, or this year is not a leap year.
        //

        public override Result<int> GetLeapMonth(int year, int era)
        {
            if (era != CurrentEra && era != ADEra)
            {
                //throw new ArgumentOutOfRangeException("era", Environment.GetResourceString("ArgumentOutOfRange_InvalidEraValue"));
				return .Err;
            }
            if (year < 1 || year > MaxYear) {
                /*throw new ArgumentOutOfRangeException(
                            "year",
                            String.Format(
                                CultureInfo.CurrentCulture,
                                Environment.GetResourceString("ArgumentOutOfRange_Range"), 1, MaxYear));*/
				return .Err;
            }
            //Contract.EndContractBlock();
            return (0);
        }

        // Checks whether a given month in the specified era is a leap month. This method returns true if
        // month is a leap month, or false if not.
        //

        public override Result<bool> IsLeapMonth(int year, int month, int era)
        {
            if (era != CurrentEra && era != ADEra) {
                //throw new ArgumentOutOfRangeException("era", Environment.GetResourceString("ArgumentOutOfRange_InvalidEraValue"));
				return .Err;
            }

            if (year < 1 || year > MaxYear) {
                /*throw new ArgumentOutOfRangeException(
                            "year",
                            String.Format(
                                CultureInfo.CurrentCulture,
                                Environment.GetResourceString("ArgumentOutOfRange_Range"), 1, MaxYear));*/
				return .Err;
            }

            if (month < 1 || month > 12) {
                /*throw new ArgumentOutOfRangeException("month", Environment.GetResourceString("ArgumentOutOfRange_Range",
                    1, 12));*/
				return .Err;
            }
            //Contract.EndContractBlock();
            return (false);

        }

        // Checks whether a given year in the specified era is a leap year. This method returns true if
        // year is a leap year, or false if not.
        //

        public override Result<bool> IsLeapYear(int year, int era) {
            if (era == CurrentEra || era == ADEra) {
                if (year >= 1 && year <= MaxYear) {
                    return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0));
                }

                /*throw new ArgumentOutOfRangeException(
                            "year",
                            String.Format(
                                CultureInfo.CurrentCulture,
                                Environment.GetResourceString("ArgumentOutOfRange_Range"), 1, MaxYear));*/
				return .Err;
            }
            //throw new ArgumentOutOfRangeException("era", Environment.GetResourceString("ArgumentOutOfRange_InvalidEraValue"));
			return .Err;
        }

        // Returns the date and time converted to a DateTime value.  Throws an exception if the n-tuple is invalid.
        //

        public override Result<DateTime> ToDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era)
        {
            if (era == CurrentEra || era == ADEra) {
                //return new DateTime(year, month, day, hour, minute, second, millisecond);
				return .Err;
            }
            //throw new ArgumentOutOfRangeException("era", Environment.GetResourceString("ArgumentOutOfRange_InvalidEraValue"));
			return .Err;
        }

        protected override bool TryToDateTime(int year, int month, int day, int hour, int minute, int second, int millisecond, int era, out DateTime result) {
            if (era == CurrentEra || era == ADEra) {
                switch (DateTime.[Friend]TryCreate(year, month, day, hour, minute, second, millisecond))
				{
				case .Ok(out result):
					return true;
				case .Err:
				}
            }
            result = DateTime.MinValue;
            return false;
        }

        private const int DEFAULT_TWO_DIGIT_YEAR_MAX = 2029;


        public override int TwoDigitYearMax
        {
            get {
                if (twoDigitYearMax == -1) {
                    twoDigitYearMax = GetSystemTwoDigitYearSetting([Friend]ID, DEFAULT_TWO_DIGIT_YEAR_MAX);
                }
                return (twoDigitYearMax);
            }

            set {
                this.[Friend]VerifyWritable();
                if (value < 99 || value > MaxYear) {
                    /*throw new ArgumentOutOfRangeException(
                                "year",
                                String.Format(
                                    CultureInfo.CurrentCulture,
                                    Environment.GetResourceString("ArgumentOutOfRange_Range"),
                                    99,
                                    MaxYear));*/
					Runtime.FatalError();
                }
                twoDigitYearMax = value;
            }
        }


        public override Result<int> ToFourDigitYear(int year) {
            if (year < 0) {
                /*throw new ArgumentOutOfRangeException("year",
                    Environment.GetResourceString("ArgumentOutOfRange_NeedNonNegNum"));*/
				return .Err;
            }
            //Contract.EndContractBlock();

            if (year > MaxYear) {
                /*throw new ArgumentOutOfRangeException(
                            "year",
                            String.Format(
                                CultureInfo.CurrentCulture,
                                Environment.GetResourceString("ArgumentOutOfRange_Range"), 1, MaxYear));*/
				return .Err;
            }
            return (base.ToFourDigitYear(year));
        }
    }
}
