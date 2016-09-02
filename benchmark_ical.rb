require 'benchmark/ips'
require 'active_support/time'
require 'ri_cal'
require 'ice_cube'
require 'pry'

EVENT_ICAL = <<-ICAL
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART;TZID=US/Eastern:20130321T090000
DTEND;TZID=US/Eastern:20130321T200000
RRULE:FREQ=WEEKLY;BYDAY=TH
END:VEVENT
END:VCALENDAR
ICAL

UPTO_DATE = ->{ 6.months.from_now }

def benchmark_ri_cal
  schedule = RiCal.parse_string(EVENT_ICAL).first

  schedule.occurrences(:before => UPTO_DATE.call).map do |occurrence|
    [occurrence.dtstart, occurrence.dtend]
  end
end

def benchmark_ice_cube
  # unfortunately this library doesn't support parsing ical dates with
  # timezone specifications, hence setting the start and end time
  start_time = Time.parse("2013-03-21 09:00:00 -0400").in_time_zone("US/Eastern")

  schedule = IceCube::IcalParser.schedule_from_ical(EVENT_ICAL).tap do |schedule|
    schedule.start_time = start_time
    schedule.end_time = Time.parse("2013-03-21 20:00:00 -0400").in_time_zone("US/Eastern")
  end

  schedule.occurrences_between(start_time, UPTO_DATE.call).map do |occurrence|
    [occurrence.start_time, occurrence.end_time]
  end
end

Benchmark.ips do |bench|
  bench.report("ri_cal: ") { benchmark_ri_cal }
  bench.report("ice_cube: ") { benchmark_ice_cube }

  bench.compare!
end
