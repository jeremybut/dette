require './user.rb'
require 'pry'
require 'rubygems'
require 'highline/import'

class Dette

  choose do |menu|
    menu.prompt = "> Identifiez-vous: "
    menu.choice("Créer Un Compte") { User.new.create }
    menu.choices( *User.all ) do |chosen|
      User.authentication chosen
    end 
  end
end