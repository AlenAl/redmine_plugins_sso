require_dependency 'user'
require_dependency 'setting'

class SsoController < ApplicationController

  unloadable
  before_filter :validconfig
  
  #登录SSO
  def index
    if User.current.logged?
        redirect_back_or_default home_url, :referer => true
        return 0
    end

   	sso = Sso.new
    admin_uid = params['admin_uid'] ? params['admin_uid'] : cookies['admin_uid']
    admin_key = params['admin_key'] ? params['admin_key'] : cookies['admin_key']

    if admin_uid
      @userInfo = sso.getInfo(admin_uid, admin_key)
    else
      redirect_to sso.getLoginUrl()
      return 0
    end

    if @userInfo.is_a?(String) #请求超时
      flash[:error] = l(:sso_config_http_error, @userInfo)
      #转转至主页面
      redirect_to home_url
      return -1
    end

    #sso成功
    if @userInfo.is_a?(Object) && @userInfo['ret'] > 0
      cookies[:admin_uid] = { :value => admin_uid, :expires => Time.now + 4 * 3600, :domain => '.oa.com'}
      cookies[:admin_key] = { :value => admin_key, :expires => Time.now + 4 * 3600, :domain => '.oa.com'}
      user = User.find_by_mail(@userInfo['email'])
      if user.nil?
        redmine_register(@userInfo)      
      else
        redmine_login(user)
      end
      #转转至主页面
      redirect_to home_url
    else
      #转转至登录界面
      redirect_to sso.getLoginUrl()
    end
  end

  #退出SSO
  def logout
    sso = Sso.new
    #管理员退出，需要检查sso是否可用
    if User.current['admin']
      admin_uid = params['admin_uid'] ? params['admin_uid'] : cookies['admin_uid']
      admin_key = params['admin_key'] ? params['admin_key'] : cookies['admin_key']
      userInfo = sso.getInfo(admin_uid, admin_key)
      if userInfo.is_a?(String) #请求超时
        flash[:error] = l(:sso_config_http_error, userInfo)
        #转转至主页面
        redirect_to home_url + "settings/plugin/sso"
        return -1
      end
    end

    cookies[:admin_uid] = { :value => "", :expires => Time.now - 1, :domain => '.oa.com'}
    cookies[:admin_key] = { :value => "", :expires => Time.now - 1, :domain => '.oa.com'}
    #redmine退出
    logout_user
    #转转至登录界面
    redirect_to home_url
  end

  def redmine_login(user)
    if user.active?
      user.update_column(:last_login_on, Time.now)
      self.logged_user = user
      call_hook(:controller_account_success_authentication_after, {:user => user })  
    else
      flash[:error] = l(:notice_account_pending)
    end 
  end

  def redmine_register(data)
    #检查用户名，如果存在则使用email作为用户名注册，注册时不允许用户名重复
    if User.find_by_login(data['username'])
      data['username'] = data['email']
    end

    user = nil
    user = User.new({:firstname => data['cname'], :lastname => "-", :mail => data['email']})
    user.login = data['username']
    user.password = 'password'
    user.password_confirmation = 'password'
    user.last_login_on = Time.now
    
    #0 = 禁用
    #1 = 通过邮件认证激活帐号
    #2 = 手动激活帐号
    #3 = 自动激活帐号
    case Setting.self_registration
    when '3'
      #自动激活状态
      user.activate
    else
      #其它为注册状态，需要管理员审核｛您的帐号已被成功创建，正在等待管理员的审核。｝
      user.register
    end

    save = user.save
    if save && user.active?
      self.logged_user = user
    end
    #如果是注册状态
    if user.registered?
      flash[:error] = l(:notice_account_pending) + l(:sso_registered_info, data['cname'], data['email'], data['username'], save)
    end
  end

  protected
  #验证参数
  def validconfig
    @ssoid = Setting.plugin_sso['ssoid']                #在ssoserver 中的站点id
    @secrect = Setting.plugin_sso['secrect']            #验证密钥
    @ssoUrl = Setting.plugin_sso['ssoUrl']              #验证地址
    if @ssoid.to_s == "" or @secrect.to_s == "" or @ssoUrl.to_s == ""
      flash[:error] = l(:sso_config_error)
      redirect_to home_url + "settings/plugin/sso"
    end
  end
end
