require 'redmine'

Redmine::Plugin.register :sso do
  name 'sso plugin'
  author 'AlenAl'
  description '单点登录'
  version '1.0.2'
  url 'http://mwiki.oa.com/sso'
  author_url ''

  settings :partial => 'settings/sso_settings',
	:default => {
      'status' => true, #true开启 false关闭
    }
end