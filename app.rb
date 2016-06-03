require 'bundler/setup'
Bundler.require
require 'sinatra'
require 'sinatra-websocket'
require 'thin'
require 'json'
require_relative './app/bot'

set :server, 'thin'
set :sockets, []

get '/' do
    if !request.websocket?
        erb :index
    else
        request.websocket do
            |ws|
            ws.onopen do
                puts "Connection opened"
                settings.sockets << ws
            end

            ws.onclose { puts "Connection closed" }

            ws.onmessage do |msg|
                settings.sockets.each do |conn|
                    send_msg = {"data" => msg}
                    conn.send(send_msg.to_json)
                end
                words = msg.split(" ")
                if words[0] == "bot" && words[1] == "ping" && words.length == 2 then
                    settings.sockets.each do |conn|
                        send_msg = {"data" => "pong"}
                        conn.send(send_msg.to_json)
                    end
                end
                if words[0] == "bot" && words.length == 3 then
                    input = {
                        "command": words[1],
                        "data": words[2]
                    }
                    bot = Bot.new(input)
                    bot.generateHash()
                    settings.sockets.each do |conn|
                        send_msg = {"data" => bot.hash}
                        conn.send(send_msg.to_json)
                    end
                end
            end
        end
    end
end
