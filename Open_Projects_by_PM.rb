$VERBOSE = nil
require 'tiny_tds'  
require 'net/smtp'
require 'tlsmail'
require './Config.rb'

puts "Running Open Projects by Week"

    client = TinyTds::Client.new username: DB_Username, password: DB_Password,  
    host: DB_Host, port: DB_Port,  
    database: DB_Database, azure:false
	EM_To_Name = "ENTER_TO_EMAIL_HERE"
	PM_name = "ENTER_PM_NAME_HERE"
	
today = Date.today

Last_Friday = today - 3
Last_Monday = today - 7
Last_Sunday = today - 1
#today = Time.now
#today_formatted = today.strftime("%Y-%m-%d")

Last_Friday_F = Last_Friday.strftime("%Y-%m-%d")
Last_Monday_F = Last_Monday.strftime("%Y-%m-%d")
Last_Sunday_F = Last_Sunday.strftime("%Y-%m-%d")

message = <<MESSAGE_END
From: #{EM_Fr_Name}
To: #{EM_To_Name}
MIME-Version: 1.0
Content-type: text/html
Subject: Open Projects as of Week Ending #{Last_Sunday_F}

MESSAGE_END

	results = client.execute("SELECT Projects.[Customer Number],Projects.[Project Number],Projects.[Project Manager ID],[Baseline Begin Date],'$' + convert(varchar(12),Projects.[User Defined 1],1) AS Award,'$' + convert(varchar(12),((CAST(Projects.[Unposted Billings] as decimal)) + (CAST(Projects.[Actual Billings] as decimal(10,2)))),1) AS Billings,'$' + convert(varchar(12),((CAST(Projects.[User Defined 1] as decimal)) - (CAST(Projects.[Unposted Billings] as decimal(10,2)) + (CAST(Projects.[Actual Billings] as decimal)))),1) AS DIFF FROM [TTI].[dbo].[PAProjects] AS Projects INNER JOIN [TTI].[dbo].[Customers] AS Customers ON Projects.[Customer Number] = Customers.[Customer Number] WHERE ([Status] = 'open' and [Close to Project Costs] = 'no') and (Projects.[User Defined 1] <> '') and (Projects.[Project Manager ID] = '#{PM_name}')")
	array = Array.new
	results.each do |row|  
	array.push(row)
	end

if !array.empty? 
	
	grouped = array.group_by{|t| t[0]}.values
		header = "<tr><td>Client</td> <td>Project No.</td> <td>PM</td> <td>Start</td>  <td>Award</td> <td>Billed</td> <td>Remaining</td> </tr>"
			table = grouped.map do |portion|
				"<table border=\"1\">\n" << header << "\n<tr>" << portion.map do |column|
				"<td>" << column.map do |element|
				element.to_s
			end.join("</td><td>") << "</td>"
		end.join("</tr>\n<tr>") << "</tr>\n</table>\n"
	end.join("\n")

	table = table.gsub("\"\]","")
	table = table.gsub("\[\"Customer Number\"\, \"","")
	table = table.gsub("\[\"Project Number\"\, \"","")
	table = table.gsub("\[\"Project Manager ID\"\, \"","")
	table = table.gsub("\[\"Baseline Begin Date\"\, ","")
	table = table.gsub("\[\"Award\"\, \"","")
	table = table.gsub("\[\"Billings\"\, \"","")
	table = table.gsub("\[\"DIFF\"\, \"","")
	table = table.gsub("\]","")
	table = table.gsub(" 00\:00\:00 -0400","")
	table = table.gsub(" 00\:00\:00 -0500","")

else
	
	table = "No new projects for the week?  Uhoh."
	
end

#puts table

#If there is no new projects, lets not send any email

  if table != "No new projects today." then
	
			 message << table

	 # Send email
	    Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
	    Net::SMTP.start(EM_Server, 587, EM_Host, EM_Username, EM_Password, :login) do |smtp|
		smtp.send_message message, EM_Fr_Add, EM_To_Name
		smtp.finish
		end

  else
	
	  puts "No new projects for the week?  Uhoh."

  end
		 
 puts "Finished Open Projects by Week"

