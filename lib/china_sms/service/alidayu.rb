# encoding: utf-8
module ChinaSMS
  module Service
    module Alidayu
      extend self

      SEND_URL = "https://eco.taobao.com/router/rest"
      SEND_METHOD = "alibaba.aliqin.fc.sms.num.send"

      def to(phone, content, options = {})
        options = default_options.merge options

        send_url = options[:send_url] || SEND_URL
        app_secret ||= options[:password]
        options[:app_key] ||= options[:username]
        options[:sms_param] ||= content.to_json if content.is_a? Hash
        except! options, :username, :password, :send_url
        
        results = []
        # 阿里大鱼一次最多支持200个手机号
        Array(phone).each_slice(200) do |phones|
          options[:rec_num] ||= phones.join(',')
          options[:method] = SEND_METHOD
          # 生成签名
          options[:sign] = Digest::MD5.hexdigest(app_secret + options.sort.join + app_secret).upcase
          # 发送短信
          res = Net::HTTP.post_form(URI.parse(send_url), options)
          result_json = result res.body
          result_json["error_response"]["phones"] = phones if result_json["error_response"]
          results.push(result_json)
        end
        errors = results.select{ |r| r["error_response"] }
        if errors.any?
          return { success: false, errors: errors }
        else
          return { success: true }
        end
      end

      def result body
        begin
          JSON.parse body
        rescue => e
          {
            code: 502,
            msg: "内容解析错误",
            detail: e.to_s
          }
        end
      end

      private

        def except! options = {}, *keys
          keys.each {|key| options.delete(key)}
          options
        end

        def default_options
          {
            timestamp: Time.now.strftime("%F %H:%M:%S"),
            format: 'json',
            v: '2.0',
            sms_type: 'normal',
            sms_free_sign_name: "大鱼测试",
            sign_method: "md5"
          }
        end
    end
  end
end