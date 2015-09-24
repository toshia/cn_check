# -*- coding: utf-8 -*-

require_relative 'rhenium'

module Plugin::CnCheck
  ADMIN_ID = 15926668 # toshi_a
end

Plugin.create(:cn_check) do
  @rheniums = Set.new() # Set of Plugin::CnCheck::Rhenium

  %w[cn rhe__ se4k cn_court_ cn_scaffold_ cat cn_check_check].each do |sn|
    @rheniums << Plugin::CnCheck::Rhenium.new(sn, false, 15).period
  end

  def period
    Reserver.new(8 * 60 * 60) do # 8 hours
      timestamp = ("[%{time}]" % {time: Time.new.strftime("%Y/%m/%d %H:%M")}).freeze
      report = @rheniums.sort_by(&:sn).inject(timestamp.dup) do |tweet, rhenium|
        token = "\n〄%{sn}: %{alive}" % {sn: rhenium.sn,
                                         alive: rhenium.stat ? "凍結(#{rhenium.stat})" : "生存"}
        if (tweet.size + token.size) >= 140
          Service.primary.post(message: tweet)
          timestamp + token
        else
          tweet + token end end
      Service.primary.post(message: report)
      period
    end
  end

  on_rheniumed do |rhenium|
    Service.primary.post message: "〄%{sn}: 凍結(%{stat})" % rhenium.to_h
  end

  on_unrheniumed do |rhenium|
    Service.primary.post message: "〄%{sn}: 凍結解除!" % rhenium.to_h
  end

  period
end
