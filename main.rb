require "discorb"
require "dotenv"

Dotenv.load

client = Discorb::Client.new(intents: Discorb::Intents.all)

client.once :ready do
  puts "Logged in as #{client.user}"
end

GUILD_IDS = ENV["GUILD_IDS"]&.split(",")
ALLOWED_BOTS = ENV["ALLOWED_BOTS"].split(",")

def delete_message(user, message)
  unless ALLOWED_BOTS.include?(message.author.id.to_s)
    mentions = ALLOWED_BOTS.map { |id| "<@!#{id}>" }.join(", ")
    return "このメッセージは削除できません。\n#{mentions}のメッセージだけ削除できます。"
  end
  unless message.embed&.author&.icon&.include?("/#{user.id}/")
    return "このメッセージは削除できません。\nアイコンのURLにユーザーIDが含まれていません。"
  end
  message.delete!.wait
  return "削除しました。"
end

client.message_command("メッセージを削除", guild_ids: GUILD_IDS) do |interaction, message|
  interaction.post(delete_message(interaction.fired_by, message), ephemeral: true)
end

client.on :reaction_add do |event|
  next unless event.emoji == Discorb::UnicodeEmoji["wastebasket"]
  res = delete_message(event.member, event.fetch_message)
  msg = event.channel.post("#{res}\nこのメッセージは5秒後に削除されます。").wait
  sleep 5
  msg.delete!
end

client.run ENV["TOKEN"]
