require File.expand_path('base_test_case', File.dirname(__FILE__))

class TestPublisher < Test::Unit::TestCase
  include BaseTestCase

  def config_test_accepted_methods
    @subscriber_connection_timeout = '1s'
  end

  def test_accepted_methods
    EventMachine.run {
      multi = EventMachine::MultiRequest.new

      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_test_accepted_methods_1').head)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_test_accepted_methods_2').put :body => 'body')
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_test_accepted_methods_3').post)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_test_accepted_methods_4').delete)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_test_accepted_methods_5').get)

      multi.callback  {
        assert_equal(5, multi.responses[:succeeded].length)

        assert_equal(405, multi.responses[:succeeded][0].response_header.status, "Publisher does not accept HEAD")
        assert_equal("HEAD", multi.responses[:succeeded][0].method, "Array is with wrong order")
        assert_equal("GET", multi.responses[:succeeded][0].response_header['ALLOW'], "Didn't receive the right error message")

        assert_equal(405, multi.responses[:succeeded][1].response_header.status, "Publisher does not accept PUT")
        assert_equal("PUT", multi.responses[:succeeded][1].method, "Array is with wrong order")
        assert_equal("GET", multi.responses[:succeeded][1].response_header['ALLOW'], "Didn't receive the right error message")

        assert_equal(405, multi.responses[:succeeded][2].response_header.status, "Publisher does accept POST")
        assert_equal("POST", multi.responses[:succeeded][2].method, "Array is with wrong order")
        assert_equal("GET", multi.responses[:succeeded][1].response_header['ALLOW'], "Didn't receive the right error message")

        assert_equal(405, multi.responses[:succeeded][3].response_header.status, "Publisher does not accept DELETE")
        assert_equal("DELETE", multi.responses[:succeeded][3].method, "Array is with wrong order")
        assert_equal("GET", multi.responses[:succeeded][3].response_header['ALLOW'], "Didn't receive the right error message")

        assert_not_equal(405, multi.responses[:succeeded][4].response_header.status, "Publisher does accept GET")
        assert_equal("GET", multi.responses[:succeeded][4].method, "Array is with wrong order")

        EventMachine.stop
      }
      fail_if_connecttion_error(multi)
    }
  end

  def test_access_whithout_channel_path
    headers = {'accept' => 'application/json'}

    EventMachine.run {
      sub = EventMachine::HttpRequest.new(nginx_address + '/sub/').get :head => headers, :timeout => 30
      sub.callback {
        assert_equal(0, sub.response_header.content_length, "Should response only with headers")
        assert_equal(400, sub.response_header.status, "Request was not understood as a bad request")
        assert_equal("No channel id provided.", sub.response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        EventMachine.stop
      }
      fail_if_connecttion_error(sub)
    }
  end

  def config_test_multi_channels
    @subscriber_connection_timeout = '1s'
  end

  def test_multi_channels
    EventMachine.run {
      multi = EventMachine::MultiRequest.new

      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_multi_channels_1').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_multi_channels_1.b10').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_multi_channels_2/ch_multi_channels_3').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_multi_channels_2.b2/ch_multi_channels_3').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_multi_channels_2/ch_multi_channels_3.b3').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_multi_channels_2.b2/ch_multi_channels_3.b3').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/ch_multi_channels_4.b').get)

      multi.callback  {
        assert_equal(7, multi.responses[:succeeded].length)
        0.upto(6) do |i|
          assert_equal(200, multi.responses[:succeeded][i].response_header.status, "Subscriber not accepted")
        end

        EventMachine.stop
      }
      fail_if_connecttion_error(multi)
    }
  end

  def config_test_max_channel_id_length
    @max_channel_id_length = 5
  end

  def test_max_channel_id_length
    headers = {'accept' => 'application/json'}
    channel = '123456'

    EventMachine.run {
      sub = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s ).get :head => headers, :timeout => 30
      sub.callback {
        assert_equal(0, sub.response_header.content_length, "Should response only with headers")
        assert_equal(400, sub.response_header.status, "Request was not understood as a bad request")
        assert_equal("Channel id is too large.", sub.response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        EventMachine.stop
      }
      fail_if_connecttion_error(sub)
    }
  end

  def test_cannot_access_a_channel_with_id_ALL
    headers = {'accept' => 'application/json'}
    channel = 'ALL'

    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s).get :head => headers, :timeout => 30
      sub_1.callback {
        assert_equal(403, sub_1.response_header.status, "Channel was created")
        assert_equal(0, sub_1.response_header.content_length, "Received response for creating channel with id ALL")
        assert_equal("Channel id not authorized for this method.", sub_1.response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        EventMachine.stop
      }
      fail_if_connecttion_error(sub_1)
    }
  end

  def config_test_broadcast_channels_without_common_channel
    @subscriber_connection_timeout = '1s'
    @broadcast_channel_prefix = "bd_"
  end

  def test_broadcast_channels_without_common_channel
    headers = {'accept' => 'application/json'}

    EventMachine.run {
      multi = EventMachine::MultiRequest.new

      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/bd_test_broadcast_channels_without_common_channel').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/bd_').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/bd1').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/bd').get)

      multi.callback  {
        assert_equal(4, multi.responses[:succeeded].length)

        assert_equal(0, multi.responses[:succeeded][0].response_header.content_length, "Should response only with headers")
        assert_equal(403, multi.responses[:succeeded][0].response_header.status, "Request was not understood as a bad request")
        assert_equal("Subscribed too much broadcast channels.", multi.responses[:succeeded][0].response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        assert_equal(nginx_address + '/sub/bd_test_broadcast_channels_without_common_channel', multi.responses[:succeeded][0].uri.to_s, "Array is with wrong order")

        assert_equal(0, multi.responses[:succeeded][1].response_header.content_length, "Should response only with headers")
        assert_equal(403, multi.responses[:succeeded][1].response_header.status, "Request was not understood as a bad request")
        assert_equal("Subscribed too much broadcast channels.", multi.responses[:succeeded][1].response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        assert_equal(nginx_address + '/sub/bd_', multi.responses[:succeeded][1].uri.to_s, "Array is with wrong order")

        assert_equal(200, multi.responses[:succeeded][2].response_header.status, "Channel id starting with different prefix from broadcast was not accept")
        assert_equal(nginx_address + '/sub/bd1', multi.responses[:succeeded][2].uri.to_s, "Array is with wrong order")

        assert_equal(200, multi.responses[:succeeded][3].response_header.status, "Channel id starting with different prefix from broadcast was not accept")
        assert_equal(nginx_address + '/sub/bd', multi.responses[:succeeded][3].uri.to_s, "Array is with wrong order")

        EventMachine.stop
      }
      fail_if_connecttion_error(multi)
    }
  end

  def config_test_broadcast_channels_with_common_channels
    @subscriber_connection_timeout = '1s'
    @authorized_channels_only  = "off"
    @broadcast_channel_prefix = "bd_"
    @broadcast_channel_max_qtd = 2
  end

  def test_broadcast_channels_with_common_channels
    headers = {'accept' => 'application/json'}

    EventMachine.run {
      multi = EventMachine::MultiRequest.new

      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/bd1/bd2/bd3/bd4/bd_1/bd_2/bd_3').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/bd1/bd2/bd_1/bd_2').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/bd1/bd_1').get)
      multi.add(EventMachine::HttpRequest.new(nginx_address + '/sub/bd1/bd2').get)

      multi.callback  {
        assert_equal(4, multi.responses[:succeeded].length)

        assert_equal(0, multi.responses[:succeeded][0].response_header.content_length, "Should response only with headers")
        assert_equal(403, multi.responses[:succeeded][0].response_header.status, "Request was not understood as a bad request")
        assert_equal("Subscribed too much broadcast channels.", multi.responses[:succeeded][0].response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        assert_equal(nginx_address + '/sub/bd1/bd2/bd3/bd4/bd_1/bd_2/bd_3', multi.responses[:succeeded][0].uri.to_s, "Array is with wrong order")

        assert_equal(200, multi.responses[:succeeded][1].response_header.status, "Request was not understood as a bad request")
        assert_equal(nginx_address + '/sub/bd1/bd2/bd_1/bd_2', multi.responses[:succeeded][1].uri.to_s, "Array is with wrong order")

        assert_equal(200, multi.responses[:succeeded][2].response_header.status, "Channel id starting with different prefix from broadcast was not accept")
        assert_equal(nginx_address + '/sub/bd1/bd_1', multi.responses[:succeeded][2].uri.to_s, "Array is with wrong order")

        assert_equal(200, multi.responses[:succeeded][3].response_header.status, "Channel id starting with different prefix from broadcast was not accept")
        assert_equal(nginx_address + '/sub/bd1/bd2', multi.responses[:succeeded][3].uri.to_s, "Array is with wrong order")

        EventMachine.stop
      }
      fail_if_connecttion_error(multi)
    }
  end

  def config_test_subscribe_an_absent_channel_with_authorized_only_on
    @authorized_channels_only = 'on'
  end

  def test_subscribe_an_absent_channel_with_authorized_only_on
    headers = {'accept' => 'application/json'}
    channel = 'ch_test_subscribe_an_absent_channel_with_authorized_only_on'

    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s).get :head => headers, :timeout => 30
      sub_1.callback {
        assert_equal(403, sub_1.response_header.status, "Channel was founded")
        assert_equal(0, sub_1.response_header.content_length, "Recieved a non empty response")
        assert_equal("Subscriber could not create channels.", sub_1.response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        EventMachine.stop
      }
      fail_if_connecttion_error(sub_1)
    }
  end

  def config_test_subscribe_an_existing_channel_with_authorized_only_on
    @authorized_channels_only = 'on'
    @subscriber_connection_timeout = '1s'
  end

  def test_subscribe_an_existing_channel_with_authorized_only_on
    headers = {'accept' => 'application/json'}
    channel = 'ch_test_subscribe_an_existing_channel_with_authorized_only_on'
    body = 'body'

    #create channel
    publish_message(channel, headers, body)

    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s).get :head => headers, :timeout => 30
      sub_1.callback {
        assert_equal(200, sub_1.response_header.status, "Channel was founded")
        EventMachine.stop
      }
      fail_if_connecttion_error(sub_1)
    }
  end

  def config_test_subscribe_an_existing_channel_and_absent_broadcast_channel_with_authorized_only_on
    @authorized_channels_only = 'on'
    @subscriber_connection_timeout = '1s'
    @broadcast_channel_prefix = "bd_"
    @broadcast_channel_max_qtd = 1
  end

  def test_subscribe_an_existing_channel_and_absent_broadcast_channel_with_authorized_only_on
    headers = {'accept' => 'application/json'}
    channel = 'ch_test_subscribe_an_existing_channel_and_absent_broadcast_channel_with_authorized_only_on'
    broadcast_channel = 'bd_test_subscribe_an_existing_channel_and_absent_broadcast_channel_with_authorized_only_on'

    body = 'body'

    #create channel
    publish_message(channel, headers, body)

    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s + '/' + broadcast_channel.to_s).get :head => headers, :timeout => 30
      sub_1.callback {
        assert_equal(200, sub_1.response_header.status, "Channel was founded")
        EventMachine.stop
      }
      fail_if_connecttion_error(sub_1)
    }
  end

  def config_test_subscribe_an_existing_channel_without_messages_and_with_authorized_only_on
    @min_message_buffer_timeout = '1s'
    @authorized_channels_only = 'on'
  end

  def test_subscribe_an_existing_channel_without_messages_and_with_authorized_only_on
    headers = {'accept' => 'application/json'}
    channel = 'ch_test_subscribe_an_existing_channel_without_messages_and_with_authorized_only_on'

    body = 'body'

    #create channel
    publish_message(channel, headers, body)
    sleep(2) #to ensure message was gone

    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s).get :head => headers, :timeout => 30
      sub_1.callback {
        assert_equal(403, sub_1.response_header.status, "Channel was founded")
        assert_equal(0, sub_1.response_header.content_length, "Recieved a non empty response")
        assert_equal("Subscriber could not create channels.", sub_1.response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        EventMachine.stop
      }
      fail_if_connecttion_error(sub_1)
    }
  end

  def config_test_subscribe_an_existing_channel_without_messages_and_absent_broadcast_channel_and_with_authorized_only_on_should_fail
    @min_message_buffer_timeout = '1s'
    @authorized_channels_only = 'on'
    @broadcast_channel_prefix = "bd_"
    @broadcast_channel_max_qtd = 1
  end

  def test_subscribe_an_existing_channel_without_messages_and_absent_broadcast_channel_and_with_authorized_only_on_should_fail
    headers = {'accept' => 'application/json'}
    channel = 'ch_test_subscribe_an_existing_channel_without_messages_and_absent_broadcast_channel_and_with_authorized_only_on_should_fail'
    broadcast_channel = 'bd_test_subscribe_an_existing_channel_without_messages_and_absent_broadcast_channel_and_with_authorized_only_on_should_fail'

    body = 'body'

    #create channel
    publish_message(channel, headers, body)
    sleep(2) #to ensure message was gone

    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s + '/' + broadcast_channel.to_s).get :head => headers, :timeout => 30
      sub_1.callback {
        assert_equal(403, sub_1.response_header.status, "Channel was founded")
        assert_equal(0, sub_1.response_header.content_length, "Recieved a non empty response")
        assert_equal("Subscriber could not create channels.", sub_1.response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
        EventMachine.stop
      }
      fail_if_connecttion_error(sub_1)
    }
  end

  def config_test_retreive_old_messages_in_multichannel_subscribe
    @header_template = 'HEADER'
    @message_template = '{\"channel\":\"~channel~\", \"id\":\"~id~\", \"message\":\"~text~\"}'
  end

  def test_retreive_old_messages_in_multichannel_subscribe
    headers = {'accept' => 'application/json'}
    channel_1 = 'ch_test_retreive_old_messages_in_multichannel_subscribe_1'
    channel_2 = 'ch_test_retreive_old_messages_in_multichannel_subscribe_2'
    channel_3 = 'ch_test_retreive_old_messages_in_multichannel_subscribe_3'

    body = 'body'

    #create channels with some messages
    1.upto(3) do |i|
      publish_message(channel_1, headers, body + i.to_s)
      publish_message(channel_2, headers, body + i.to_s)
      publish_message(channel_3, headers, body + i.to_s)
    end

    response = ""
    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel_1.to_s + '/' + channel_2.to_s + '.b5' + '/' + channel_3.to_s + '.b2').get :head => headers, :timeout => 30
      sub_1.stream { |chunk|
        response += chunk
        lines = response.split("\r\n")

        if lines.length >= 6
          assert_equal('HEADER', lines[0], "Header was not received")
          line = JSON.parse(lines[1])
          assert_equal(channel_2.to_s, line['channel'], "Wrong channel")
          assert_equal('body1', line['message'], "Wrong message")
          assert_equal(1, line['id'].to_i, "Wrong message")

          line = JSON.parse(lines[2])
          assert_equal(channel_2.to_s, line['channel'], "Wrong channel")
          assert_equal('body2', line['message'], "Wrong message")
          assert_equal(2, line['id'].to_i, "Wrong message")

          line = JSON.parse(lines[3])
          assert_equal(channel_2.to_s, line['channel'], "Wrong channel")
          assert_equal('body3', line['message'], "Wrong message")
          assert_equal(3, line['id'].to_i, "Wrong message")

          line = JSON.parse(lines[4])
          assert_equal(channel_3.to_s, line['channel'], "Wrong channel")
          assert_equal('body2', line['message'], "Wrong message")
          assert_equal(2, line['id'].to_i, "Wrong message")

          line = JSON.parse(lines[5])
          assert_equal(channel_3.to_s, line['channel'], "Wrong channel")
          assert_equal('body3', line['message'], "Wrong message")
          assert_equal(3, line['id'].to_i, "Wrong message")

          EventMachine.stop
        end
      }
      fail_if_connecttion_error(sub_1)
    }
  end

  def config_test_max_number_of_channels
    @max_number_of_channels = 1
  end

  def test_max_number_of_channels
    headers = {'accept' => 'application/json'}
    channel = 'ch_test_max_number_of_channels_'

    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s + 1.to_s).get :head => headers, :timeout => 30
      sub_1.stream {
        assert_equal(200, sub_1.response_header.status, "Channel was not created")
        assert_not_equal(0, sub_1.response_header.content_length, "Should response channel info")

        sub_2 = EventMachine::HttpRequest.new(nginx_address + '/sub/' + channel.to_s + 2.to_s).get :head => headers, :timeout => 30
        sub_2.callback {
          assert_equal(403, sub_2.response_header.status, "Request was not forbidden")
          assert_equal(0, sub_2.response_header.content_length, "Should response only with headers")
          assert_equal("Number of channels were exceeded.", sub_2.response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
          EventMachine.stop
        }
        fail_if_connecttion_error(sub_2)
      }
      fail_if_connecttion_error(sub_1)
    }

  end

  def config_test_max_number_of_broadcast_channels
    @max_number_of_broadcast_channels = 1
    @broadcast_channel_prefix = 'bd_'
    @broadcast_channel_max_qtd = 1
  end

  def test_max_number_of_broadcast_channels
    headers = {'accept' => 'application/json'}
    channel = 'bd_test_max_number_of_broadcast_channels_'

    EventMachine.run {
      sub_1 = EventMachine::HttpRequest.new(nginx_address + '/sub/ch1/' + channel.to_s + 1.to_s).get :head => headers, :timeout => 30
      sub_1.stream {
        assert_equal(200, sub_1.response_header.status, "Channel was not created")
        assert_not_equal(0, sub_1.response_header.content_length, "Should response channel info")

        sub_2 = EventMachine::HttpRequest.new(nginx_address + '/sub/ch1/' + channel.to_s + 2.to_s).get :head => headers, :timeout => 30
        sub_2.callback {
          assert_equal(403, sub_2.response_header.status, "Request was not forbidden")
          assert_equal(0, sub_2.response_header.content_length, "Should response only with headers")
          assert_equal("Number of channels were exceeded.", sub_2.response_header['X_NGINX_PUSHSTREAM_EXPLAIN'], "Didn't receive the right error message")
          EventMachine.stop
        }
        fail_if_connecttion_error(sub_2)
      }
      fail_if_connecttion_error(sub_1)
    }
  end
end
