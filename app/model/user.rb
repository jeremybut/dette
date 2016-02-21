require 'json'
require 'digest'
require 'pry'

class User

  attr_accessor :name, :password, :recipient, :how_much

  def create
    u = User.new
    u.name = ask("Nom?") { |q| q.validate = /^[A-z]+$/ }.strip.downcase
    u.password = ask("Mot de passe:") { |q| q.echo = "x" }.strip.downcase
    u.update
  end

  def update
    tmp_user = {
      "name": self.name,
      "password": self.encrypt_md5(self.password)
    }
    datas = JSON.parse(File.read('../data/datas.json'), symbolize_names: true)
    datas[:users] << tmp_user
    File.open("../data/datas.json","w") do |f|
      f.puts JSON.pretty_generate(datas)
    end
    self.index
  end

  def update_debt
    datas = JSON.parse(File.read('../data/datas.json'), symbolize_names: true)

    user = datas[:users].find {|u| u[:name] == self.name}
    has_debts = user.keys.include? :debts
    u_index = datas[:users].index(user)

    if has_debts
      exist = user[:debts].find {|d| d[:recipient] == self.recipient}
      if exist
        d_index = user[:debts].index(exist)
        new_debt = datas[:users][u_index][:debts][d_index][:how_much] = exist[:how_much] + self.how_much
        File.open("../data/datas.json","w") do |f|
          f.puts JSON.pretty_generate(datas)
        end
        puts "Tu dois maintenant #{new_debt} à #{self.recipient.capitalize}"
        self.index
      else
        tmp_debt = {
          "recipient": self.recipient,
          "how_much": self.how_much
        }
        datas[:users][u_index][:debts] << tmp_debt
        File.open("../data/datas.json","w") do |f|
          f.puts JSON.pretty_generate(datas)
        end
      end
    else
      tmp_debt = [{
        "recipient": self.recipient,
        "how_much": self.how_much
      }]        
      datas[:users][u_index][:debts] = tmp_debt
      File.open("../data/datas.json","w") do |f|
        f.puts JSON.pretty_generate(datas)
      end      
    end
  end

  def self.authentication name
    u = User.new
    u.name = name.downcase
    password = ask("Mot de passe:") { |q| q.echo = "x" } 
    datas = JSON.parse(File.read('../data/datas.json'), symbolize_names: true)
    user_pwd = datas[:users].find {|h| h[:name] == u.name}[:password]
    if u.encrypt_md5(password) == user_pwd
      u.index
    else
      puts "Le mot de passe est incorrect !"
      User.authentication name
    end    
  end

  def self.all
    datas = File.read('../data/datas.json')
    parsed = datas && datas.length >= 2 ? JSON.parse(datas, symbolize_names: true) : nil
    users = parsed[:users].map{|u| u[:name].capitalize} if parsed
  end

  def index
    puts "Bonjour #{self.name.capitalize}, actions possibles :"
    user_menu
  end

  def owe_money
    puts "A qui ?"
    choose do |menu|
      menu.choices( *User.all ) do |whose|
        self.recipient = whose.downcase
        self.how_much = ask("Combien?  ", Integer) {} 
        self.update_debt
      end 
    end
  end

  def owes_me_money
  end

  def show_debts
  end

  def user_menu
    choose do |menu|
      menu.choice("Je dois de l'argent") { self.owe_money }
      menu.choice("Quelqu'un me doit de l'argent") { self.owes_me_money }
      menu.choice("Afficher mes dettes et creances") { self.show_debts }
      menu.choice("Quitter") { exit }
    end
  end

  def encrypt_md5(text)
    Digest::MD5.hexdigest text
  end

end