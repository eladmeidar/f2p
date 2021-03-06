require 'test_helper'

class EntryHelperTest < MyActionView::TestCaseWithController
  def setup
    super
    @ctx = EntryController::EntryContext.new(auth)
    @user_profiles = {}
    @room_profiles = {}
  end

  #
  # tests for ApplicationHelper
  #
  test "self_label" do
    assert_equal('You', self_label)
  end

  test "inline_meta" do
    assert_match(/viewport/, inline_meta)
    @controller.request.stubs(:user_agent).returns('iPhone')
    assert_match(/viewport/, inline_meta)
  end

  test "inline_stylesheet" do
    assert(inline_stylesheet)
    assert_no_match(/webkit/, inline_stylesheet)
    @controller.request.stubs(:user_agent).returns('iPod')
    assert_match(/webkit/, inline_stylesheet)
  end

  test "icon_url" do
    assert_equal(F2P::Config.icon_url_base + 'star.png', icon_url(:star))
    assert_equal(F2P::Config.icon_url_base + 'foo.png', icon_url('foo.png'))
  end

  test "icon_tag" do
    str = icon_tag(:star)
    assert_match(%r(<img), str)
    assert_match(%r(\balt="star"), str)
    assert_match(%r(\bheight="16"), str)
    assert_match(%r(\bwidth="16"), str)
    assert_match(%r(\bsrc=".*/images/icons/star.png), str)
    assert_match(%r(\btitle="star"), str)
  end

  test "icon_tag with label" do
    str = icon_tag(:star, 'custom label')
    assert_match(%r(<img), str)
    assert_match(%r(\balt="custom label"), str)
    assert_match(%r(\bheight="16"), str)
    assert_match(%r(\bwidth="16"), str)
    assert_match(%r(\bsrc=".*/images/icons/star.png), str)
    assert_match(%r(\btitle="custom label"), str)
  end

  test "icon_tag with _" do
    str = icon_tag('media_disabled')
    assert_match(%r(<img), str)
    assert_match(%r(\balt="media disabled"), str)
    assert_match(%r(\bheight="16"), str)
    assert_match(%r(\bwidth="16"), str)
    assert_match(%r(\bsrc=".*/images/icons/image_link.png), str)
    assert_match(%r(\btitle="media disabled"), str)
  end

  test 'service_icon' do
    service = Service[
      "name"=>"FriendFeed",
      "iconUrl"=> "http://iconUrl/",
      "entryType"=>"link",
      "id"=>"internal",
      "profileUrl"=>"http://profileUrl"
    ]
    assert_equal(%Q(<a href="http://www.google.com/gwt/n?u=http%3A%2F%2FprofileUrl"><img alt="FriendFeed" height="16" src="http://iconUrl/" title="filter by FriendFeed" width="16" /></a>), service_icon(service))
    # no link
    service = Service[
      "name"=>"FriendFeed",
      "iconUrl"=> "http://iconUrl/",
      "entryType"=>"link",
      "id"=>"internal"
    ]
    assert_equal(%Q(<img alt="FriendFeed" height="16" src="http://iconUrl/" title="FriendFeed" width="16" />), service_icon(service))
    # no icon_url
    service = Service[
      "name"=>"FriendFeed",
      "entryType"=>"link",
      "id"=>"internal"
    ]
    assert_nil(service_icon(service))
  end

  test 'list_name' do
    lists = [{'nickname' => 'n1', 'name' => 'name1'}, {'nickname' => 'n2', 'name' => 'name2'}].map { |e| List[e] }
    User.expects(:ff_profile).with(auth, 'user1').
      returns({'lists' => lists}).times(1)
    assert_equal('name1', list_name('n1'))
    assert_equal('name1', list_name('n1'))
    assert_equal('name2', list_name('n2'))
    assert_equal(nil, list_name('n3'))
  end

  test 'room_name' do
    Room.expects(:ff_profile).with(auth, 'nick').
      returns({'name' => 'name'}).times(1)
    assert_equal('name', room_name('nick'))
    assert_equal('name', room_name('nick'))
    assert_equal('name', room_name('nick'))
    assert_equal('name', room_name('nick'))
  end

  test 'room_picture' do
    Room.expects(:ff_profile).with(auth, 'nick').
      returns({'name' => 'name', 'url' => 'http://url/'}).times(1)
    Room.expects(:ff_picture_url).with('nick', 'small').
      returns('http://picture/').times(2)
    str = %Q(<a href="http://www.google.com/gwt/n?u=http%3A%2F%2Furl%2F"><img alt="nick" class="profile" height="25" src="http://picture/" title="nick" width="25" /></a>)
    assert_equal(0, room_picture_with_link('nick').index(str))
    assert_equal(0, room_picture_with_link('nick', 'small').index(str))
  end

  test 'room_members' do
    members = ['u1', 'u2']
    Room.expects(:ff_profile).with(auth, 'nick').
      returns({'members' => members}).times(1)
    assert_equal(members, room_members('nick'))
    assert_equal(members, room_members('nick'))
  end

  test 'user_name' do
    User.expects(:ff_profile).with(auth, 'nick').
      returns({'name' => 'name'}).times(1)
    assert_equal('name', user_name('nick'))
    assert_equal('name', user_name('nick'))
  end

  test 'user_status' do
    User.expects(:ff_status_map).with(auth, ['nick']).
      returns({'nick' => 'status'}).times(1)
    assert_equal('status', user_status('nick'))
    assert_equal('status', user_status('nick'))
  end

  test 'user_picture' do
    User.expects(:ff_profile).with(auth, 'nick').
      returns({'id' => 'id', 'name' => 'name', 'profileUrl' => 'http://url/'}).times(1)
    User.expects(:ff_picture_url).with('nick', 'small').
      returns('http://picture/').times(2)
    str = %Q(<a href="http://www.google.com/gwt/n?u=http%3A%2F%2Furl%2F"><img alt="nick" class="profile" height="25" src="http://picture/" title="nick" width="25" /></a>)
    assert_equal(0, user_picture_with_link('nick').index(str))
    assert_equal(0, user_picture_with_link('nick', 'small').index(str))
  end

  test 'user_picture self' do
    User.expects(:ff_profile).with(auth, 'user1').
      returns({'id' => 'id', 'name' => 'name', 'profileUrl' => 'http://url/'}).times(1)
    User.expects(:ff_picture_url).with('user1', 'small').
      returns('http://picture/').times(2)
    str = %Q(<a href="http://www.google.com/gwt/n?u=http%3A%2F%2Furl%2F"><img alt="You" class="profile" height="25" src="http://picture/" title="You" width="25" /></a>)
    assert_equal(0, user_picture_with_link('user1').index(str))
    assert_equal(0, user_picture_with_link('user1', 'small').index(str))
  end

  test 'user_services' do
    services = ['s1', 's2']
    User.expects(:ff_profile).with(auth, 'nick').
      returns({'services' => services}).times(1)
    assert_equal(services, user_services('nick'))
    assert_equal(services, user_services('nick'))
  end

  test 'user_rooms' do
    rooms = ['r1', 'r2']
    User.expects(:ff_profile).with(auth, 'nick').
      returns({'rooms' => rooms}).times(1)
    assert_equal(rooms, user_rooms('nick'))
    assert_equal(rooms, user_rooms('nick'))
  end

  test 'user_lists' do
    lists = ['l1', 'l2']
    User.expects(:ff_profile).with(auth, 'nick').
      returns({'lists' => lists}).times(1)
    assert_equal(lists, user_lists('nick'))
    assert_equal(lists, user_lists('nick'))
  end

  test 'user_subscriptions' do
    subscriptions = ['u1', 'u2']
    User.expects(:ff_profile).with(auth, 'nick').
      returns({'subscriptions' => subscriptions}).times(1)
    assert_equal(subscriptions, user_subscriptions('nick'))
    assert_equal(subscriptions, user_subscriptions('nick'))
  end

  test 'user' do
    user = {
      "name"=>"NAKAMURA, Hiroshi",
      "nickname"=>"nahi",
      "id"=>"95f306fd-0f63-47f2-88fc-8480ff10d48e",
      "profileUrl"=>"http://friendfeed.com/nahi"
    }
    entry = Entry['user' => user]
    assert_equal(%Q(<a href="/foo/entry/list\?user=nahi">NAKAMURA, Hiroshi</a>), user(entry))
    entry.user.nickname = 'user1'
    assert_equal(%Q(<a href="/foo/entry/list\?user=user1">You</a>), user(entry))
  end

  test 'via' do
    via = {"name"=>"mail2ff", "url"=>"http://mail2ff.com/"}
    entry = Entry['via' => via]
    assert_equal(%Q(from <a href="http://www.google.com/gwt/n?u=http%3A%2F%2Fmail2ff.com%2F">mail2ff</a>), via(entry))
    via = {"name"=>"mail2ff", "url"=>nil}
    entry = Entry['via' => via]
    assert_equal(%Q(from mail2ff), via(entry))
  end

  test 'image_size' do
    assert_equal("5x4", image_size(5, 4))
  end

  test 'date compact' do
    Time.stubs(:now).returns(Time.mktime(2009, 1, 1, 0, 0, 0))
    assert_nil(date(nil))
    assert_equal(%Q(<span class="older">(08/01/01)</span>), date(Time.mktime(2008, 1, 1, 0, 0, 0)))
    assert_equal(%Q(<span class="older">(01/04)</span>), date(Time.mktime(2008, 1, 4, 0, 0, 0)))
    assert_equal(%Q(<span class="older">(08/01/03)</span>), date(Time.mktime(2008, 1, 3, 0, 0, 0)))
    assert_equal(%Q(<span class="older">(12/31)</span>), date(Time.mktime(2008, 12, 31, 7, 59, 59)))
    assert_equal(%Q(<span class="older">(08:00)</span>), date(Time.mktime(2008, 12, 31, 8, 0, 0)))
  end

  test 'date compact with String' do
    Time.stubs(:now).returns(Time.mktime(2009, 1, 1, 0, 0, 0))
    assert_equal(%Q(<span class="older">(08/01/01)</span>), date(Time.mktime(2008, 1, 1, 0, 0, 0).xmlschema))
  end

  test 'date not compact' do
    Time.stubs(:now).returns(Time.mktime(2009, 1, 1, 0, 0, 0))
    assert_nil(date(nil))
    assert_equal(%Q(<span class="older">[08/01/01 00:00]</span>), date(Time.mktime(2008, 1, 1, 0, 0, 0), false))
    assert_equal(%Q(<span class="older">[01/04 00:00]</span>), date(Time.mktime(2008, 1, 4, 0, 0, 0), false))
    assert_equal(%Q(<span class="older">[08/01/03 00:00]</span>), date(Time.mktime(2008, 1, 3, 0, 0, 0), false))
  end

  test 'latest' do
    Time.stubs(:now).returns(Time.mktime(2009, 1, 1, 0, 0, 0))
    assert_nil(date(nil))
    assert_equal(%Q(<span class="latest1">(23:00)</span>), date(Time.mktime(2008, 12, 31, 23, 0, 0)))
    assert_equal(%Q(<span class="latest2">(22:59)</span>), date(Time.mktime(2008, 12, 31, 22, 59, 59)))
    assert_equal(%Q(<span class="latest2">(21:00)</span>), date(Time.mktime(2008, 12, 31, 21, 0, 0)))
    assert_equal(%Q(<span class="latest3">(20:59)</span>), date(Time.mktime(2008, 12, 31, 20, 59, 59)))
    assert_equal(%Q(<span class="latest3">(18:00)</span>), date(Time.mktime(2008, 12, 31, 18, 0, 0)))
    assert_equal(%Q(<span class="older">(17:59)</span>), date(Time.mktime(2008, 12, 31, 17, 59, 59)))
  end

  test 'url_for_app?' do
    assert(!url_for_app?('foo'))
    assert(url_for_app?('http://test.host/foo/bar/baz'))
  end

  test 'q' do
    assert_equal(%Q(&quot;foo&quot;), q('foo'))
  end

  test 'fold_length' do
    str = 'helloこんにちは'
    assert_equal(str, fold_length(str, 1000))
    assert_equal(str, fold_length(str, 10))
    assert_equal('helloこんにち', fold_length(str, 9))
    assert_equal('helloこんに', fold_length(str, 8))
    assert_equal('helloこん', fold_length(str, 7))
    assert_equal('helloこ', fold_length(str, 6))
    assert_equal('hello', fold_length(str, 5))
    assert_equal('hell', fold_length(str, 4))
    assert_equal('hel', fold_length(str, 3))
    assert_equal('he', fold_length(str, 2))
    assert_equal('h', fold_length(str, 1))
    assert_equal('', fold_length(str, 0))
    assert_equal('', fold_length(str, -1))
  end

  #
  # tests for EntryHelper
  # 
  test 'viewname' do
    assert_equal('archived', viewname)
  end

  test 'pin_link' do
    entry = read_mapped_entries('entries', 'twitter')[0]
    ctx.inbox = true
    entry.view_unread = true
    assert_match(/anchor.png/, pin_link(entry))
    entry.view_pinned = true
    assert_match(/tick.png/, pin_link(entry))
  end

  test 'icon' do
    entry = read_mapped_entries('entries', 'twitter')[0]
    assert_match(/\?service=twitter/, icon(entry))
  end

  test 'icon for room' do
    entry = read_mapped_entries('entries', 'twitter')[0]
    entry.room = Room['nickname' => 'n1', 'name' => 'nn11']
    assert_match(/\?room=n1/, icon(entry))
    assert_match(/\(nn11\)/, icon_extra(entry))
  end

  test 'content brightkite' do
    entry = read_mapped_entries('entries', 'brightkite')[0]
    assert_match(/maps.google.com\/staticmap/, content(entry))
  end

  test 'content tumblr' do
    entry = read_mapped_entries('entries', 'tumblr')[0]
    ctx.fold = true
    assert_match(/add.png/, content(entry))
  end
end
