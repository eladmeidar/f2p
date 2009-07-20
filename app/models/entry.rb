require 'hash_utils'
require 'attachment'
require 'comment'
require 'from'
require 'geo'
require 'like'
require 'thumbnail'
require 'via'


class Entry
  include HashUtils
  EMPTY = [].freeze

  class << self
    def create(opt)
      auth = opt[:auth]
      to = opt[:to]
      body = opt[:body]
      if entry = ff_client.post_entry(to, body, opt.merge(:name => auth.name, :remote_key => auth.remote_key))
        Entry[entry]
      end
    end

    def update(opt)
      auth = opt[:auth]
      eid = opt[:eid]
      if entry = ff_client.edit_entry(eid, opt.merge(:name => auth.name, :remote_key => auth.remote_key))
        Entry[entry]
      end
    end

    def delete(opt)
      auth = opt[:auth]
      id = opt[:eid]
      undelete = !!opt[:undelete]
      if undelete
        ff_client.undelete_entry(id, :name => auth.name, :remote_key => auth.remote_key)
      else
        ff_client.delete_entry(id, :name => auth.name, :remote_key => auth.remote_key)
      end
    end

    def add_comment(opt)
      auth = opt[:auth]
      id = opt[:eid]
      body = opt[:body]
      if comment = ff_client.post_comment(id, body, :name => auth.name, :remote_key => auth.remote_key)
        Comment[comment]
      end
    end

    def edit_comment(opt)
      auth = opt[:auth]
      comment = opt[:comment]
      body = opt[:body]
      if comment = ff_client.edit_comment(comment, body, :name => auth.name, :remote_key => auth.remote_key)
        Comment[comment]
      end
    end

    def delete_comment(opt)
      auth = opt[:auth]
      comment = opt[:comment]
      undelete = !!opt[:undelete]
      if undelete
        ff_client.undelete_comment(comment, :name => auth.name, :remote_key => auth.remote_key)
      else
        ff_client.delete_comment(comment, :name => auth.name, :remote_key => auth.remote_key)
      end
    end

    def add_like(opt)
      auth = opt[:auth]
      id = opt[:eid]
      ff_client.like(id, :name => auth.name, :remote_key => auth.remote_key)
    end

    def delete_like(opt)
      auth = opt[:auth]
      id = opt[:eid]
      ff_client.delete_like(id, :name => auth.name, :remote_key => auth.remote_key)
    end

    def hide(opt)
      auth = opt[:auth]
      id = opt[:eid]
      ff_client.hide_entry(id, :name => auth.name, :remote_key => auth.remote_key)
    end

    def add_pin(opt)
      auth = opt[:auth]
      id = opt[:eid]
      ActiveRecord::Base.transaction do
        unless Pin.find_by_user_id_and_eid(auth.id, id)
          pin = Pin.new
          pin.user = auth
          pin.eid = id
          pin.save!
        end
      end
    end

    def delete_pin(opt)
      auth = opt[:auth]
      id = opt[:eid]
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
  attr_accessor :body
  attr_accessor :url
  attr_accessor :link
  attr_accessor :date
  attr_accessor :from
  attr_accessor :to
  attr_accessor :thumbnails
  attr_accessor :files
  attr_accessor :comments
  attr_accessor :likes
  attr_accessor :via
  attr_accessor :geo
  attr_accessor :friend_of
  attr_accessor :checked_at
  attr_accessor :commands

  attr_accessor :twitter_username
  attr_accessor :twitter_reply_to
  attr_accessor :orphan
  attr_accessor :view_pinned
  attr_accessor :view_unread
  attr_accessor :view_nextid
  attr_accessor :view_links
  attr_accessor :view_medias
  attr_accessor :view_map

  def initialize(hash)
    initialize_with_hash(hash, 'id', 'url', 'date', 'commands')
    @link = hash['rawLink']
    if %r(\Ahttp://friendfeed.com/e/) =~ @link
      @link = nil
    end
    @commands ||= EMPTY
    @twitter_username = nil
    @twitter_reply_to = nil
    @orphan = hash['__f2p_orphan']
    @view_pinned = nil
    @view_unread = nil
    @view_nextid = nil
    @view_links = nil
    @view_medias = []
    @view_map = false
    @body = hash['rawBody']
    @from = From[hash['from']]
    @to = (hash['to'] || EMPTY).map { |e| From[e] }
    @thumbnails = (hash['thumbnails'] || EMPTY).map { |e| Thumbnail[e] }
    @files = (hash['files'] || EMPTY).map { |e| Attachment[e] }
    @comments = wrap_comment(hash['comments'] || EMPTY)
    @likes = (hash['likes'] || EMPTY).map { |e| Like[e] }
    @via = Via[hash['via']]
    @geo = Geo[hash['geo']] || extract_geo_from_google_staticmap_url(@thumbnails)
    if hash['fof']
      @friend_of = From[hash['fof']['from']]
    else
      @friend_of = nil
    end
    @checked_at = nil
    @hidden = hash['hidden'] || false
    if self.via and self.via.twitter?
      @twitter_username = (self.via.url || '').match(%r{twitter.com/([^/]+)})[1]
      if /@([a-zA-Z0-9_]+)/ =~ self.body
        @twitter_reply_to = $1
      end
    end
    @modified = nil
  end

  def similar?(rhs)
    result = false
    if self.from_id == rhs.from_id
      result ||= same_origin?(rhs)
    end
    result ||= same_link?(rhs) || similar_body?(rhs)
    if self.via and rhs.via and self.via.twitter? and rhs.via.twitter?
      result ||= self.twitter_reply_to == rhs.twitter_username || self.twitter_username == rhs.twitter_reply_to
    end
    result
  end

  def same_feed?(rhs)
    rhs and from_id == rhs.from_id and service_identity == rhs.service_identity
  end

  def service_identity
    via ? via.name : nil
  end

  def date_at
    @date_at ||= (date ? Time.parse(date) : Time.now)
  end

  def modified_at
    @modified_at ||= Time.parse(modified)
  end

  def modified
    return @modified if @modified
    @modified = self.date
    unless comments.empty?
      @modified = [@modified, comments.last.date].max
    end
    @modified || Time.now.xmlschema
  end

  def hidden?
    @hidden
  end

  def from_id
    from.id
  end

  def self_comment_only?
    cs = comments
    cs.size == 1 and self.from_id == cs.first.from_id
  end

  def origin_id
    if !orphan
      from_id
    end
  end

private

  def wrap_comment(comments)
    index = 0
    comments.map { |e|
      c = Comment[e]
      index += 1
      c.index = index
      c.entry = self
      c
    }
  end

  def extract_geo_from_google_staticmap_url(tbs)
    tbs.each do |tb|
      if /maps.google.com\/staticmap\b.*\bmarkers=([0-9\.]+),([0-9\.]+)\b/ =~ tb.url
        self.view_map = true
        return Geo['lat' => $1, 'long' => $2]
      end
    end
    nil
  end

  def same_origin?(rhs)
    (self.date_at - rhs.date_at).abs < 30.seconds
  end

  def similar_body?(rhs)
    t1 = self.body
    t2 = rhs.body
    t1 == t2 or part_of(t1, t2) or part_of(t2, t1)
  end

  def same_link?(rhs)
    self.url and rhs.url and self.url == rhs.url
  end

  def part_of(base, part)
    base and part and base.index(part) and part.length > base.length / 2
  end
end
