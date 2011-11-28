require 'cora'
require 'siri_objects'
require 'open-uri'
require 'nokogiri'

#############
# This is a plugin for SiriProxy that will allow you to check tonight's hockey scores
# Example usage: "What's the score of the Avalanche game?"
#############

class SiriProxy::Plugin::HockeyScores < SiriProxy::Plugin
  @firstTeamName   = ""
  @firstTeamScore  = ""
  @secondTeamName  = ""
  @secondTeamScore = ""

  def initialize(config)
    # if you have custom configuration options, process them here!
  end

  listen_for /score of the (.*) game/i do |phrase|
    team = pickOutTeam(phrase)
    score(team) # in the function, request_completed will be called when the thread is finished
  end

  def score(userTeam)
    Thread.new do
      doc = Nokogiri::HTML(open("http://www.nhl.com/ice/m_scores.htm"))
      scores = doc.css(".gmDisplay")

      scores.each do |score|
        team = score.css(".blkcolor")
        team.each do |teamname|
          if teamname.content.strip.downcase == userTeam.downcase
            firstTeam       = score.css("tr:nth-child(2)").first
            @firstTeamName  = firstTeam.css(".blkcolor").first.content.strip
            @firstTeamScore = firstTeam.css("td:nth-child(2)").first.content.strip

            secondTeam       = score.css("tr:nth-child(3)").first
            @secondTeamName  = secondTeam.css(".blkcolor").first.content.strip
            @secondTeamScore = secondTeam.css("td:nth-child(2)").first.content.strip
            break
          end
        end
      end

      response = if @firstTeamName == "" || @secondTeamName == ""
        "No games involving the #{userTeam} were found playing tonight"
      else
        "The score for the #{userTeam} game is: #{@firstTeamName} (#{firstTeamScore}), #{@secondTeamName} (#{@secondTeamScore})"
      end

      @firstTeamName = ""
      @secondTeamName = ""

      say response

      request_completed
    end

    say "Checking on tonight's hockey games"
  end

  def pickOutTeam(phrase)
    case phrase
    when /anaheim/i                            then "Ducks"
    when /boston/i                             then "Bruins"
    when /buffalo/i                            then "Sabres"
    when /calgary/i                            then "Flames"
    when /carolina/i, /canes/i                 then "Hurricanes"
    when /chicago/i, /hawks/i                  then "Blackhawks"
    when /colorado/i, /aves/i                  then "Avalanche"
    when /columbus/i, /jackets/i               then "Blue Jackets"
    when /dallas/i                             then "Stars"
    when /detroit/i                            then "Red Wings"
    when /edmonton/i                           then "Oilers"
    when /florida/i                            then "Panthers"
    when /L.A/i, /angeles/i                    then "Kings"
    when /minnesota/i, /minny/i                then "Wild"
    when /montr.*al/i, /canadi.*ns/i, /habs/i  then "Canadiens"
    when /nashville/i, /preds/i                then "Predators"
    when /jersey/i                             then "Devils"
    when /islanders/i                          then "Islanders"
    when /rangers/i                            then "Rangers"
    when /ottawa/i, /sens/i                    then "Senators"
    when /philadelphia/i, /philly/i, /fliers/i then "Flyers"
    when /phoenix/i, /yotes/i                  then "Coyotes"
    when /pittsburgh/i, /pens/i                then "Penguins"
    when /san/i, /jose/i                       then "Sharks"
    when /louis/i, /saint/i                    then "Blues"
    when /tampa/i, /bay/i                      then "Lightning"
    when /toronto/i, /leafs/i                  then "Maple Leafs"
    when /vancouver/i, /nucks/i                then "Canucks"
    when /washington/i, /caps/i                then "Capitals"
    when /winnipeg/i                           then "Jets"
    else phrase
    # The above should catch city names, team nicknames, or words which Siri would misinterpret
    # If the person said the team name verbatim as NHL needs just return it
  end
end
