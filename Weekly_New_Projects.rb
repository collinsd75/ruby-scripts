$VERBOSE = nil
require 'tiny_tds'  
require 'net/smtp'
require 'tlsmail'
require './Config.rb'

puts "Running Projects by Week"

    client = TinyTds::Client.new username: DB_Username, password: DB_Password,  
    host: DB_Host, port: DB_Port,  
    database: DB_Database, azure:false
	EM_To_Name = "ENTER_TO_EMAIL_HERE"
	
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
Subject: New Projects for Week Ending #{Last_Sunday_F}

MESSAGE_END

	results = client.execute("SELECT [Customer Number],[Project ID],[Project Name],[Department],[Estimator ID],[Project Manager ID], '$' + convert(varchar(12),[User Defined 1],1) AS [User Defined 1] FROM [TTI].[dbo].[PAProjects] WHERE ([Baseline Begin Date] >= '#{Last_Monday_F}' AND [Baseline Begin Date] <= '#{Last_Friday_F}' AND [Status] = 'Open')")  
	array = Array.new
	results.each do |row|  
	array.push(row)
	end

if !array.empty? 
	
	grouped = array.group_by{|t| t[0]}.values
		header = "<tr><td>Client</td> <td>Project No.</td> <td>Project Name</td> <td>Department</td>  <td>Salesperson</td> <td>Project Manager</td> <td>Award Amount</td> </tr>"
			table = grouped.map do |portion|
				"<table border=\"1\">\n" << header << "\n<tr>" << portion.map do |column|
				"<td>" << column.map do |element|
				element.to_s
			end.join("</td><td>") << "</td>"
		end.join("</tr>\n<tr>") << "</tr>\n</table>\n"
	end.join("\n")

	table = table.gsub("\"\]","")
	table = table.gsub("\[\"Customer Number\"\, \"","")
	table = table.gsub("\[\"Project ID\"\, \"","")
	table = table.gsub("\[\"Project Name\"\, \"","")
	table = table.gsub("\[\"Department\"\, \"","")
	table = table.gsub("\[\"Estimator ID\"\, \"","")
	table = table.gsub("\[\"Project Manager ID\"\, \"","")
	table = table.gsub("\[\"User Defined 1\"\, \"","")
	table = table.gsub("\]","")
	table = table.gsub(" 00\:00\:00 -0400","")

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
		 
 puts "Finished Projects by Week"

