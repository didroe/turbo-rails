module Turbo
  class FrameRedirectMiddleware
    FRAME_PARAM = "turbo_frame"
    FRAME_HEADER = "Turbo-Frame"
    LOCATION_HEADER = "Location"

    def initialize(app)
      @app = app
    end

    def call(env)
      query_frame = pop_query_param(env)

      status, headers, body = @app.call(env)

      add_query_frame_to_headers(query_frame, headers)
      add_frame_to_redirect(status, headers)

      [status, headers, body]
    end

    private

    def pop_query_param(env)
      query_params = Rack::Utils.parse_query(env["QUERY_STRING"], "&")
      value = query_params.delete(FRAME_PARAM)
      return if value.nil?

      env["QUERY_STRING"] = Rack::Utils.build_query(query_params)

      # I'm not that familiar with how the env is used, but potentially
      # env["REQUEST_URI"] and env["ORIGINAL_FULLPATH"] need updating too

      value
    end

    def add_query_frame_to_headers(query_frame, headers)
      return if query_frame.blank?
      return if headers[FRAME_HEADER].present? # Overridden by the app

      headers[FRAME_HEADER] = query_frame
    end

    def add_frame_to_redirect(status, headers)
      return unless status == 302 || status == 303 # Only for temporary redirects

      target_frame = headers[FRAME_HEADER]
      location = headers[LOCATION_HEADER]
      return if target_frame.blank? || location.blank?

      join_char = location.include?("?") ? "&" : "?"

      headers[LOCATION_HEADER] = "#{location}#{join_char}#{FRAME_PARAM}=#{target_frame}"
    end
  end
end
