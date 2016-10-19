# name: Community trello
# about: Integrate bitnami community and trello
# version: 0.1.0
# authors: Javier J. Salmeron

after_initialize do
  DiscourseEvent.on(:post_created) do |*params|
    next unless SiteSetting.trello_enabled

    begin
      post, opts, user = params
      topic = post.topic
      next if topic.try(:private_message?)
      status = "Open"
      category = Category.find(post.topic.category_id)
      category_name = category.name   	
   
      if (user.groups.include?(Group.find(SiteSetting.admin_group_id)))
        status = "Pending"
      end

      topic_url = "#{Discourse.base_url}#{post.url}"

      uri = URI.parse(SiteSetting.trello_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.path)
      request.add_field('Content-Type', 'application/json')
      request.body = {
            :add => (post.try(:is_first_post?) ? "true" : "false"),
            :title => topic.title,
            :status => status,
            :type => "CommunitySupportTicket",
            :url => topic.url,
            :ticket => topic.id,
            :apikey => SiteSetting.trello_apikey,
            :token => SiteSetting.trello_token,
            :agent => user.username,
	        :user => user.username,
	        :category => category_name
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
