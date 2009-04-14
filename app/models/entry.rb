require 'hash_utils'


class Entry
  include HashUtils
  EMPTY = [].freeze

  class << self
    def create(opt)
      auth = opt[:auth]
      body = opt[:body]
      link = opt[:link]
      comment = opt[:comment]
      images = opt[:images]
      files = opt[:files]
      room = opt[:room]
      entry = ff_client.post(auth.name, auth.remote_key, body, link, comment, images, files, room)
      if entry
        entry.first['id']
      end
    end

    def delete(opt)
      auth = opt[:auth]
      id = opt[:id]
      undelete = !!opt[:undelete]
      ff_client.delete(auth.name, auth.remote_key, id, undelete)
    end

    def add_comment(opt)
      auth = opt[:auth]
      id = opt[:id]
      body = opt[:body]
      comment = ff_client.post_comment(auth.name, auth.remote_key, id, body)
      if comment
        comment['id']
      end
    end

    def edit_comment(opt)
      auth = opt[:auth]
      id = opt[:id]
      comment = opt[:comment]
      body = opt[:body]
      comment = ff_client.edit_comment(auth.name, auth.remote_key, id, comment, body)
      if comment
        comment['id']
      end
    end

    def delete_comment(opt)
      auth = opt[:auth]
      id = opt[:id]
      comment = opt[:comment]
      undelete = !!opt[:undelete]
      ff_client.delete_comment(auth.name, auth.remote_key, id, comment, undelete)
    end

    def add_like(opt)
      auth = opt[:auth]
      id = opt[:id]
      ff_client.like(auth.name, auth.remote_key, id)
    end

    def delete_like(opt)
      auth = opt[:auth]
      id = opt[:id]
      ff_client.unlike(auth.name, auth.remote_key, id)
    end

    def add_pin(opt)
      auth = opt[:auth]
      id = opt[:id]
      unless Pin.find_by_user_id_and_eid(auth.id, id)
        pin = Pin.new
        pin.user = auth
        pin.eid = id
        raise unless pin.save
      end
    end

    def delete_pin(opt)
      auth = opt[:auth]
      id = opt[:id]
      if pin = Pin.find_by_user_id_and_eid(auth.id, id)
        raise unless pin.destroy
      end
    end

  private

    def ff_client
      ApplicationController.ff_client
    end
  end

  attr_accessor :id
  attr_accessor :title
  attr_accessor :link
  attr_accessor :updated
  attr_accessor :published
  attr_accessor :service
  attr_accessor :user
  attr_accessor :medias
  attr_accessor :comments
  attr_accessor :likes
  attr_accessor :via
  attr_accessor :room
  attr_accessor :geo
  attr_accessor :friend_of

  attr_accessor :twitter_username
  attr_accessor :twitter_reply_to
  attr_accessor :view_pinned
  attr_accessor :view_inbox
  attr_accessor :view_links

  def initialize(hash)
    initialize_with_hash(hash, 'id', 'title', 'link', 'updated', 'published')
    @service = Service[hash['service']]
    @user = EntryUser[hash['user']]
    @medias = (hash['media'] || EMPTY).map { |e| Media[e] }
    @comments = (hash['comments'] || EMPTY).map { |e|
      c = Comment[e]
      c.entry = self
      c
    }
    @likes = (hash['likes'] || EMPTY).map { |e| Like[e] }
    @via = Via[hash['via']]
    @room = Room[hash['room']]
    @geo = Geo[hash['geo']]
    @friend_of = EntryUser[hash['friendof']]
    @hidden = hash['hidden'] || false
    @twitter_username = nil
    @twitter_reply_to = nil
    @view_pinned = nil
    @view_inbox = nil
    @view_likns = nil
    if self.service and self.service.twitter?
      @twitter_username = (self.service.profile_url || '').sub(/\A.*\//, '')
      if /@([a-zA-Z0-9_]+)/ =~ self.title
        @twitter_reply_to = $1
      end
    end
  end

  def similar?(rhs)
    result = false
    if self.user_id == rhs.user_id
      result ||= same_origin?(rhs)
    end
    result ||= same_link?(rhs) || similar_title?(rhs)
    if self.service.twitter? and rhs.service.twitter?
      result ||= self.twitter_reply_to == rhs.twitter_username || self.twitter_username == rhs.twitter_reply_to
    end
    result
  end

  def service_identity
    [service.id, room]
  end

  def published_at
    @published_at ||= Time.parse(published)
  end

  def modified_at
    @modified_at ||= Time.parse(modified)
  end

  def modified
    return @modified if @modified
    @modified = self.updated || self.published
    unless comments.empty?
      @modified = [@modified, comments.last.date].max
    end
    unless likes.empty?
      @modified = [@modified, likes.last.date].max
    end
    @modified
  end

  def hidden?
    @hidden
  end

  def user_id
    user.id
  end

  def nickname
    user.nickname
  end

  def self_comment_only?
    cs = comments
    cs.size == 1 and self.user_id == cs.first.user_id
  end

private

  def same_origin?(rhs)
    (self.published_at - rhs.published_at).abs < 10.seconds
  end

  def similar_title?(rhs)
    t1 = self.title
    t2 = rhs.title
    t1 == t2 or part_of(t1, t2) or part_of(t2, t1)
  end

  def same_link?(rhs)
    self.link and rhs.link and self.link == rhs.link
  end

  def part_of(base, part)
    base.index(part) and part.length > base.length / 2
  end
end
