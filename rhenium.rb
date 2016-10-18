# -*- coding: utf-8 -*-

module Plugin::CnCheck
  Rhenium = Struct.new(:sn, :stat, :error_count) do
    # このレニウムがレニウムされているか否かを返す
    # ==== Return
    # レニウムされていれば真。どちらかわからない場合はnil
    def rheniumed?
      if stat
        stat end end

    # レニウムされている時に呼ぶ
    # ==== Args
    # [new_stat] Object エラーステータス
    # ==== Return
    # self
    def rheniumed!(new_stat)
      case new_stat
      when new_stat.is_a?(MikuTwitter::RateLimitError)
      # Rate limit exceed. Ignore.
      when new_stat.is_a?(MikuTwitter::Error) && new_stat.httpresponse.code[0] == '5'
      # Flying whale. Ignore.
      else
        self.error_count += 1
        if self.error_count == 3 or (self.error_count > 3 and !compare(self.stat, new_stat))
          Plugin.call(:rheniumed, self) end
        self.stat = new_stat end end

    # 残念ながら、レニウムされていない時に呼ぶ
    # ==== Return
    # self
    def unrheniumed!
      self.error_count = 0
      if self.stat
        Plugin.call(:unrheniumed, self) end
      self.stat = false end

    def compare(a, b)
      a = a.code if a.respond_to?(:code)
      b = b.code if b.respond_to?(:code)
      a == b end

    def period
      Reserver.new(60 * (self.stat ? [15, self.error_count].min : 15)) do
        (Service.primary/:users/:show).json(screen_name: self.sn).next{
          self.unrheniumed!
        }.trap { |err|
          self.rheniumed! err
        }.trap{ |err|
          error err
        }.next{ period } end
      self end
  end
end
