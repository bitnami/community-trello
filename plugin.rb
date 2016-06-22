# name: Community trello
# about: Integrate bitnami community and trello
# version: 0.2.0
# authors: Bernd Ahlers

after_initialize do
  DiscourseEvent.on(:post_created) do |*params|
    next unless SiteSetting.trello_enabled

    begin
      Rails.logger.info("Inside the plugin")
      post, opts, user = params
      Rails.logger.info("Post = #{post}, opts = #{opts}, user = #{user}")
      topic = post.topic

      topic_url = "#{Discourse.base_url}#{post.url}"

      uri = URI.parse(SiteSetting.trello_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/json')
      request.body = {
            :add => (post.try(:is_first_post?) ? "true" : "false"),
            :title => topic.title,
            :url => topic.url,
            :ticket => topic.id,
            :apikey => SiteSetting.trello_apikey,
            :token => SiteSetting.trello_token 
      }.to_json

      response = http.request(request)
      case response
      when Net::HTTPSuccess
        Rails.logger.info("Trello webhook successfully sent to #{uri.host}. (post: #{topic_url})")
      else
        Rails.logger.error("#{uri.host}: #{response.code} - #{response.message}")
      end
    rescue => e
      Rails.logger.error("Error sending Trello hook: #{e.message}")
    end
  end
end
