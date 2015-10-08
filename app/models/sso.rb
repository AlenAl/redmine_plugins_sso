#单点登录model
require 'net/http'
require 'cgi'
require 'rubygems'
require 'json'
require 'pp'

class Sso < ActiveRecord::Base

	#构造函数
    def initialize()
        @ssoid = Setting.plugin_sso['ssoid']                #在ssoserver 中的站点id
        @secrect = Setting.plugin_sso['secrect']            #验证密钥
        @ssoUrl = Setting.plugin_sso['ssoUrl']              #验证地址
    end

    #获取用户信息
    def getInfo(admin_uid, admin_key)
        html_response   = nil
        hParams         = Hash[
                            'do'    => 'getInfo',
                            'uid'   => admin_uid, #params[:admin_uid],
                            'key'   => admin_key, #params[:admin_key],
                            'appid' => @ssoid
        ]
        return self.get_response(self.getSsoUrl(hParams))
    end

    #返回登陆首页
    def getLoginUrl()
        return "http://sso.oa.com/Index/login/appid/#{@ssoid}" 
    end

    #返回中心站点的url
    def getSsoUrl(hParams)
        return @ssoUrl + '?' + hParams.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&')
	end

    #5秒超时请求
    def get_response(url)
        begin
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.open_timeout = 5
          http.read_timeout = 5
          return JSON.parse(http.get(url).body)
        rescue Exception => e
          return e.message
        end
    end

end