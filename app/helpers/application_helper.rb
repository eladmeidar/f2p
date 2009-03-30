# Methods added to this helper will be available to all templates in the application.

require 'time'


module ApplicationHelper
  APPNAME = 'f2p'
  DATE_THRESHOLD = (24 - 8).hours
  YEAR_THRESHOLD = 1.year
  SELF_LABEL = 'You'
  GWT_URL_BASE = 'http://www.google.com/gwt/n?u='
  ICON_NAME = {
    'star' => 'star.png',
    #'star' => 'heart.png', # for special 2/14 configuration!
    'like' => 'thumb_up.png',
    'comment' => 'comment.png',
    'friend_comment' => 'user_comment.png',
    'comment_add' => 'comment_add.png',
    'delete' => 'delete.png',
    'more' => 'add.png',
    'write' => 'pencil_add.png',
    'settings' => 'cog_edit.png',
    'search' => 'find.png',
    'logout' => 'user_go.png',
    'previous' => 'resultset_previous.png',
    'next' => 'resultset_next.png',
    'url' => 'world_link.png',
    'reshare' => 'pencil_go.png',
    'related' => 'link.png',
    'go' => 'page_white_world.png',
    'media_disabled' => 'image_link.png',
    'pinned' => 'tick.png',
    'pin' => 'anchor.png',
    'bottom' => 'arrow_down.png',
    'top' => 'arrow_up.png',
    'map' => 'map.png',
    'help' => 'help.png',
  }

  def jpmobile?
    @controller.request.respond_to?(:mobile)
  end

  def iphone?
    /(iPhone|iPod)/ =~ @controller.request.user_agent
  end

  def inline_meta
    if iphone?
      <<__EOS__
<meta name="viewport" content="width=device-width; initial-scale=1.0" />
__EOS__
    end
  end

  def inline_stylesheet
    return if jpmobile? and @controller.request.mobile.is_a?(Jpmobile::Mobile::Docomo)
    h1_size = setting.font_size + 1
    h2_size = setting.font_size
    body_size = setting.font_size
    <<__EOS__
<style type="text/css">
  h1 { font-size: #{h1_size}pt; }
  h2 { font-size: #{h2_size}pt; }
  body { font-size: #{body_size}pt; }
  a img { border: none; }
  img.media   { border: 1px solid #ccc; padding: 1px; }
  img.profile { border: 1px solid #ccc; padding: 0px; }
  p.message { color: red; }
  .latest1 { color: #F00; }
  .latest2 { color: #C00; }
  .latest3 { color: #900; }
  .older { color: #008; }
  .comment { color: #333; }
  .inbox { font-weight: bold; }
  div.listings .thread1 { padding-bottom: 0.8ex; background-color: #EEE; }
  div.listings .thread2 { padding-bottom: 0.8ex; }
  div.listings ul {
    list-style-type: none;
    margin-top: 0pt;
    margin-bottom: 0pt;
  }
  div.listings p {
    margin-top: 0pt;
    margin-bottom: 0pt;
  }
  #{ inline_stylesheet_iphone }
</style>
__EOS__
  end

  def inline_stylesheet_iphone
    if iphone?
      <<__EOS__
  body {
    -webkit-user-select: none;
    -webkit-text-size-adjust: none;
  }
__EOS__
    end
  end

  def top_menu
    write_new_link +
      search_link +
      settings_link +
      logout_link +
      help_link
  end

  def self_label
    SELF_LABEL
  end

  def icon_url(name)
    F2P::Config.icon_url_base + (ICON_NAME[name.to_s] || name.to_s)
  end

  def icon_tag(name, alt = nil)
    name = name.to_s
    label = alt || name.gsub(/_/, ' ')
    image_tag(icon_url(name), :alt => h(label), :title => h(label), :size => '16x16')
  end

  def write_new_link
    link_to(icon_tag(:write), :controller => 'entry', :action => 'new')
  end

  def search_link
    link_to(icon_tag(:search), :controller => 'entry', :action => 'search')
  end

  def settings_link
    link_to(icon_tag(:settings), :controller => 'setting', :action => 'index')
  end

  def logout_link
    link_to(icon_tag(:logout), :controller => 'login', :action => 'clear')
  end

  def help_link
    link_to(icon_tag(:help), :controller => 'help', :action => 'index')
  end

  def u(arg)
    if arg
      super(arg)
    end
  end

  def appname
    h(APPNAME)
  end

  def setting
    @setting
  end

  def auth
    @auth
  end

  def service_icon(service, link = nil)
    icon_url = v(service, 'iconUrl')
    name = v(service, 'name')
    link ||= v(service, 'profileUrl')
    if icon_url and name
      if link
        label = "filter by #{name}"
        link_to(image_tag(icon_url, :alt => h(name), :title => h(label)), link)
      else
        image_tag(icon_url, :alt => h(name), :title => h(name))
      end
    end
  end

  def list_name(nickname)
    if found = user_lists(auth.name).find { |e| v(e, 'nickname') == nickname }
      v(found, 'name')
    end
  end

  def room_name(nickname)
    session_cache(:room, :ff_name, nickname) {
      Room.ff_name(:auth => auth, :room => nickname)
    }
  end

  def room_description(nickname)
    session_cache(:room, :description, nickname) {
      Room.description(:auth => auth, :room => nickname)
    }
  end

  def room_picture(nickname, size = 'small')
    name = room_name(nickname)
    image_url = session_cache(:room, :pictur_url, nickname, size) {
      Room.picture_url(:auth => auth, :room => nickname, :size => size)
    }
    url = session_cache(:room, :ff_url, nickname) {
      Room.ff_url(:auth => auth, :room => nickname)
    }
    link_to(image_tag(image_url, :class => h('profile'), :alt => h(name), :title => h(name), :size => image_size(25, 25)), url)
  end

  def room_members(nickname)
    session_cache(:room, :members, nickname) {
      Room.members(:auth => auth, :room => nickname)
    }
  end

  def user_id(nickname)
    session_cache(:user, :ff_id, nickname) {
      User.ff_id(:auth => auth, :user => nickname)
    }
  end

  def user_name(nickname)
    session_cache(:user, :ff_name, nickname) {
      User.ff_name(:auth => auth, :user => nickname)
    }
  end

  def user_status(nickname)
    session_cache(:user, :status, nickname) {
      User.status(:auth => auth, :user => nickname)
    }
  end

  def user_picture(nickname, size = 'small')
    return if user_id(nickname) == nickname
    name = user_name(nickname)
    if nickname == auth.name
      name = self_label
    end
    image_url = session_cache(:user, :pictur_url, nickname, size) {
      User.picture_url(:auth => auth, :user => nickname, :size => size)
    }
    url = session_cache(:user, :ff_url, nickname) {
      User.ff_url(:auth => auth, :user => nickname)
    }
    link_to(image_tag(image_url, :class => h('profile'), :alt => h(name), :title => h(name), :size => image_size(25, 25)), url)
  end

  def user_services(nickname)
    session_cache(:user, :services, nickname) {
      User.services(:auth => auth, :user => nickname)
    }
  end

  def user_rooms(nickname)
    session_cache(:user, :rooms, nickname) {
      User.rooms(:auth => auth, :user => nickname)
    }
  end

  def user_lists(nickname)
    session_cache(:user, :lists, nickname) {
      User.lists(:auth => auth, :user => nickname)
    }
  end

  def user_subscriptions(nickname)
    session_cache(:user, :subscriptions, nickname) {
      User.subscriptions(:auth => auth, :user => nickname)
    }
  end

  def user(user)
    user_id = v(user, 'id')
    nickname = v(user, 'nickname')
    name = v(user, 'name')
    if nickname == auth.name
      name = self_label
    end
    link_to(h(name), :controller => 'entry', :action => 'list', :user => u(nickname || user_id))
  end

  def via(via)
    name = v(via, 'name')
    link = v(via, 'url')
    if link
      %Q[via #{link_to(h(name), link)}]
    elsif name
      %Q[via #{h(name)}]
    end
  end

  def image_size(width, height)
    "#{width}x#{height}"
  end

  def date(time, compact = true)
    return unless time
    unless time.is_a?(Time)
      time = Time.parse(time.to_s).localtime
    end
    elapsed = Time.now - time
    format = nil
    if !compact
      if elapsed > YEAR_THRESHOLD
        format = "[%y/%m/%d %H:%M]"
      else
        format = "[%m/%d %H:%M]"
      end
    else
      if elapsed > YEAR_THRESHOLD
        format = "(%y/%m/%d)"
      elsif elapsed > DATE_THRESHOLD
        format = "(%m/%d)"
      else
        format = "(%H:%M)"
      end
    end
    body = h(time.strftime(format))
    latest(time, body)
  end

  def latest(time, body)
    case elapsed(time)
    when (-1.hour)..(1.hour) # may have a time lag
      %Q[<span class="latest1">#{body}</span>]
    when 0..3.hour
      %Q[<span class="latest2">#{body}</span>]
    when 0..6.hour
      %Q[<span class="latest3">#{body}</span>]
    else
      %Q[<span class="older">#{body}</span>]
    end
  end

  def elapsed(time)
    if time
      Time.now - time
    end
  end

  def link_to(markup, *rest)
    if rest.size == 1 and rest.first.is_a?(String) and !url_for_app?(rest.first)
      opt = {}
      opt[:target] = '_blank' if setting.link_open_new_window
      if setting.link_type == 'gwt'
        return super(markup, GWT_URL_BASE + u(rest.first), opt)
      else
        return super(markup, rest.first, opt)
      end
    end
    super
  end

  def url_for_app?(url)
    !!url.index(url_for(:only_path => false, :controller => '')) or url[0] == ?#
  end

  def link_url(url)
    link_to(h(url), url)
  end

  def q(str)
    h('"') + str + h('"')
  end

  def v(hash, *keywords)
    keywords.inject(hash) { |r, k|
      r[k] if r
    }
  end

  def fold_length(str, length)
    len = length.to_i
    return '' if len <= 0
    str.scan(Regexp.new("^.{0,#{len.to_s}}", Regexp::MULTILINE, 'u'))[0] || ''
  end

private

  def session_cache(*key, &block)
    @controller.request.session[key] ||= yield
  end
end
