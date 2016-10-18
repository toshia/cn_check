# -*- coding: utf-8 -*-

require_relative 'rhenium'

module Plugin::CnCheck
  ADMIN_ID = 15926668 # toshi_a
  DURATION = 8 * 60 * 60
  REPORT_TIME = Enumerator.new do |y|
    now = Time.now
    current = Time.new(now.year, now.month, now.day, 5)
    loop do
      break if current > now
      current += DURATION end
    loop do
      y << current
      current += DURATION end
  end
end

Plugin.create(:cn_check) do
  @rheniums = Set.new() # Set of Plugin::CnCheck::Rhenium

  %w[cn rhe__ se4k cn_court_ cn_scaffold_ cat cn_check_check aclog_bot aclog_service re4k].each do |sn|
    @rheniums << Plugin::CnCheck::Rhenium.new(sn, nil, 15).period
  end

  def period
    Plugin::CnCheck::REPORT_TIME.each do |nex|
      promise = Queue.new
      notice "next check time: #{nex}"
      Reserver.new(nex) do # 8 hours
        timestamp = ("[%{time}]" % {time: Time.new.strftime("%Y/%m/%d %H:%M")}).freeze
        report = @rheniums.sort_by(&:sn).inject(timestamp.dup) do |tweet, rhenium|
          token = "\n〄%{sn}: %{alive}" % {sn: rhenium.sn,
                                           alive: rhenium.stat ? "凍結(#{stat_convert(rhenium.stat)})" : "生存"}
          if (tweet.size + token.size) >= 140
            Plugin.call(:cn_check_report, tweet)
            timestamp + token
          else
            tweet + token end end
        Plugin.call(:cn_check_report, report)
        promise.push(true)
      end
      promise.pop
    end
  end

  def stat_convert(stat)
    case stat
    when MikuTwitter::TwitterError
      "#{stat.code} #{stat.message}"
    when MikuTwitter::Error
      stat_convert(stat.httpresponse)
    when Net::HTTPResponse
      "#{stat.code} #{stat.message}"
    when Exception
      "#{stat.class} #{stat.message}"
    else
      stat.class.to_s end end

  on_rheniumed do |rhenium|
    Plugin.call :cn_check_report, "〄%{sn}: 凍結(%{stat})" % {stat: stat_convert(rhenium.stat), sn: rhenium.sn}
  end

  on_unrheniumed do |rhenium|
    Plugin.call :cn_check_report, "〄%{sn}: 凍結解除!" % rhenium.to_h
  end

  on_cn_check_report do |report|
    Service.primary.post(message: report)
  end

  Thread.new {
    period }.trap{|err| error err }
end
