module CoreExtensions
  module Array
    module DuplicatesCounter
      def count_duplicates
        self.each_with_object(Hash.new(0)) { |element, counter| counter[element] += 1 }.sort_by{|k,v| -v}.to_h
      end
    end
  end
end
Array.include CoreExtensions::Array::DuplicatesCounter
module IB

# define a custom ErrorClass which can be fired if a verification fails
class VerifyError < StandardError
end

class Contract

# Reading Contract-Defaults
	#
# by default, the yml-file in the base-directory (ib-ruby) is used.
# This method can be overloaded to include a file from a different location
	#
#  IB::Symbols::Stocks.wfc.yml_file
#   => "/home/ubuntu/workspace/ib-ruby/contract_config.yml" 
# 
    def yml_file
      File.expand_path('../../../../contract_config.yml',__FILE__ )
    end
# IB::Contract#Verify 
 
# verifies the contract 
#
# returns the number of contracts retured by the TWS.
# 
# 
# The method accepts a block. The  queried contract-Object is assessible there.
# If multible contracts are specified, the block is executed with each of these contracts.
#
# Parameter: thread: (true/false) 
#
# The verifiying-process ist time consuming. If multible contracts are to be verified, 
# they can be queried simultaniously.
#    IB::Symbols::W500.map{|c|  c.verify(thread: true){ |vc| do_something }}.join
# 
# A simple verification works as follows:
# 
#  s = IB::Stock.new symbol:"A"  
#  s --> <IB::Stock:0x007f3de81a4398 
#  	  @attributes= {"symbol"=>"A", "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART"}> 
#  s.verify   --> 1
#  # s is unchanged !
#	 
#  s.verify{ |c| puts c.inspect }
#   --> <IB::Stock:0x007f3de81a4398
#       @attributes={"symbol"=>"A",  "updated_at"=>2015-04-17 19:20:00 +0200,
# 		  "sec_type"=>"STK", "currency"=>"USD", "exchange"=>"SMART", 
# 		  "con_id"=>1715006, "expiry"=>"", "strike"=>0.0, "local_symbol"=>"A",
# 		  "multiplier"=>0, "primary_exchange"=>"NYSE"}, 
#       @contract_detail=#<IB::ContractDetail:0x007f3de81ed7c8 
# 		    @attributes={"market_name"=>"A", "trading_class"=>"A", "min_tick"=>0.01,
# 		    "order_types"=>"ACTIVETIM, (...),WHATIF,", 
# 		    "valid_exchanges"=>"SMART,NYSE,CBOE,ISE,CHX,(...)PSX", 
# 		    "price_magnifier"=>1, "under_con_id"=>0, 
# 		    "long_name"=>"AGILENT TECHNOLOGIES INC", "contract_month"=>"",
# 		    "industry"=>"Industrial", "category"=>"Electronics",
# 		    "subcategory"=>"Electronic Measur Instr", "time_zone"=>"EST5EDT",
# 		    "trading_hours"=>"20150417:0400-2000;20150420:0400-2000",
# 		    "liquid_hours"=>"20150417:0930-1600;20150420:0930-1600", 
# 		    "ev_rule"=>0.0, "ev_multiplier"=>"", "sec_id_list"=>{}, 
# 		    "updated_at"=>2015-04-17 19:20:00 +0200, "coupon"=>0.0, 
# 		    "callable"=>false, "puttable"=>false, "convertible"=>false,
# 		    "next_option_partial"=>false}>> 
# 
# 
		def  verify  thread: nil,  &b 
				_verify update: false, thread: thread,  &b  # returns the allocated threads
			end # def

# Verify that the contract is a valid IB::Contract, update the Contract-Object and return it.
#
# Returns nil if the contract could not be verified. 
# 
#	 > s =  Stock.new symbol: 'AA'
#     => #<IB::Stock:0x0000000002626cc0 
#        @attributes={:symbol=>"AA", :con_id=>0, :right=>"", :include_expired=>false, 
#                     :sec_type=>"STK", :currency=>"USD", :exchange=>"SMART"}
#  > sp  = s.verify! &.essential
#     => #<IB::Stock:0x00000000025a3cf8 
#        @attributes={:symbol=>"AA", :con_id=>251962528, :exchange=>"SMART", :currency=>"USD",
#                     :strike=>0.0, :local_symbol=>"AA", :multiplier=>0, :primary_exchange=>"NYSE", 
#                     :trading_class=>"AA", :sec_type=>"STK", :right=>"", :include_expired=>false}
#                   
#  > s =  Stock.new symbol: 'invalid'
#     =>  @attributes={:symbol=>"invalid", :sec_type=>"STK", :currency=>"USD", :exchange=>"SMART"}
#  >  sp  = s.verify! &.essential
#     => nil

			def verify!
				c =  0
				_verify( update: true){| response | c+=1 } # wait for the returned thread to finish
				IB::Connection.logger.error { "Multible Contracts detected during verify!."  } if c > 1
				con_id.to_i < 0 || contract_detail.is_a?(ContractDetail) ? self :  nil
			end

# Resets a Contract to enable a renewed ContractData-Request via Contract#verify
# 
# Standardattributes to reset: :con_id, :last_trading_day, :contract_detail
# 
# Additional Attributes can be specified ie.
# 
# 	e =  IB::Symbols::Futures.es
# 	e.verify! 
# 	e.reset_attributes! :expiry
# 	e.verify!
# 	--> IB::VerifyError (Currency, Exchange, Expiry, Symbol are needed to retrieve Contract,).

			def reset_attributes! *attr
				# modifies the contract
				attr = ( attr +  [:con_id, :last_trading_day ]).uniq
				attr.each{|y| @attributes[y] = nil }
				self.contract_detail =  nil if contract_detail.present?
			end
			# returns a copy of the contract with modifications
			def reset_attributes *attr
				e= essential	
				e.reset_attributes! *attr 
				e
	end
# Ask for the Market-Price and store item in IB::Contract.misc
# 
# For valid contracts, either bid/ask or last_price and close_price are transmitted.
# 
# If last_price is recieved, its returned. 
# If not, midpoint (bid+ask/2) is used. Else the closing price will be returned.
# 
# Any  value (even 0.0) which is stored in IB::Contract.misc indicates that the contract is 
# accepted by `place_order`.
# 
# The result can be costomized by a provided block.
# 
# 	IB::Symbols::Stocks.sie.market_price{ |x| puts x.inspect; x[:last] }.to_f
# 	-> {"bid"=>0.10142e3, "ask"=>0.10144e3, "last"=>0.10142e3, "close"=>0.10172e3}
# 	-> 101.42 
# 
# assigns IB::Symbols.sie.misc with the value of the :last (or delayed_last) TickPrice-Message
# and returns this value, too
			def market_price delayed:  true, thread: false

				tws=  Connection.current 		 # get the initialized ib-ruby instance
				the_id =  nil
				tickdata =  Hash.new
				# define requested tick-attributes
				last, close, bid, ask	 = 	[ [ :delayed_last , :last_price ] , [:delayed_close , :close_price ],
																[  :delayed_bid , :bid_price ], [  :delayed_ask , :ask_price ]] 
				request_data_type =  delayed ? :frozen_delayed :  :frozen

				tws.send_message :RequestMarketDataType, :market_data_type =>  IB::MARKET_DATA_TYPES.rassoc( request_data_type).first

				#keep the method-call running until the request finished
				#and cancel subscriptions to the message handler
				# method returns the (running) thread
				th = Thread.new do
					finalize= false
					# subscribe to TickPrices
					s_id = tws.subscribe(:TickSnapshotEnd) { |msg|	finalize = true	if msg.ticker_id == the_id }
					e_id = tws.subscribe(:Alert){|x|  finalize = true if x.code == 354 && x.error_id == the_id } 
					# TWS Error 354: Requested market data is not subscribed.
					sub_id = tws.subscribe(:TickPrice ) do |msg| #, :TickSize,  :TickGeneric, :TickOption) do |msg|
						[last,close,bid,ask].each do |x| 
							tickdata[x] = msg.the_data[:price] if x.include?( IB::TICK_TYPES[ msg.the_data[:tick_type]]) 
							finalize = true if tickdata.size ==4  || ( tickdata[bid].present? && tickdata[ask].present? )  
						end if  msg.ticker_id == the_id 
					end
					# initialize »the_id« that is used to identify the received tick messages
					# by fireing the market data request
					the_id = tws.send_message :RequestMarketData,  contract: self , snapshot: true 

					begin
						# todo implement config-feature to set timeout in configuration   (DRY-Feature)
						Timeout::timeout(5) do   # max 5 sec.
							loop{ break if finalize ; sleep 0.1 } 
							# reduce :close_price delayed_close  to close a.s.o 
							tz = -> (z){ z.map{|y| y.to_s.split('_')}.flatten.count_duplicates.max_by{|k,v| v}.first.to_sym}
							data =  tickdata.map{|x,y| [tz[x],y]}.to_h
							valid_data = ->(d){ !(d.to_i.zero? || d.to_i == -1) }
							self.misc = if block_given? 
														yield data 
														# yields {:bid=>0.10142e3, :ask=>0.10144e3, :last=>0.10142e3, :close=>0.10172e3}
													else # behavior if no block is provided
														if valid_data[data[:last]]
															data[:last] 
														elsif valid_data[data[:bid]]
															(data[:bid]+data[:ask])/2
														elsif data[:close].present? 
															data[:close]
														else
															nil
														end
													end
						end
					rescue Timeout::Error
						Connection.logger.info{ "#{to_human} --> No Marketdata recieved " }
					end
					tws.unsubscribe sub_id, s_id, e_id
				end
				if thread
					th		# return thread
				else
					th.join
					misc	# return 
				end
			end #

# returns the Option Chain of the contract (if available)
#
## parameters
### right:: :call, :put, :straddle
### ref_price::  :request or a numeric value
### sort:: :strike, :expiry 
### exchange:: List of Exchanges to be queried (Blank for all avaialable Exchanges)
		def option_chain ref_price: :request, right: :put, sort: :strike, exchange: ''

			ib =  Connection.current

			## Enable Cashing of Definition-Matrix
			@option_chain_definition ||= [] 

			my_req = nil; finalize= false
			
			# -----------------------------------------------------------------------------------------------------
			# get OptionChainDefinition from IB ( instantiate cashed Hash )
			if @option_chain_definition.blank?
				sub_sdop = ib.subscribe( :SecurityDefinitionOptionParameterEnd ) { |msg| finalize = true if msg.request_id == my_req }
				sub_ocd =  ib.subscribe( :OptionChainDefinition ) do | msg |
					if msg.request_id == my_req
						message =  msg.data
						# transfer the the first record to @option_chain_definition
						if @option_chain_definition.blank?
							@option_chain_definition =  msg.data

						end
							# override @option_chain_definition if a decent combintion of attributes is met
							# us- options:  use the smart dataset
							# other options: prefer options of the default trading class 
							if message[:currency] == 'USD' && message[:exchange] == 'SMART'	 || message[:trading_class] == symbol 
								@option_chain_definition =  msg.data

								finalize = true
							end
						end
					end
					
					verify do | c |
						my_req = ib.send_message :RequestOptionChainDefinition, con_id: c.con_id,
																			symbol: c.symbol,
																			exchange: sec_type == :future ? c.exchange : "", # BOX,CBOE',
																			sec_type: c[:sec_type]
					end

					Thread.new do  

			Timeout::timeout(1, IB::TransmissionError,"OptionChainDefinition not recieved" ) do
						loop{ sleep 0.1; break if finalize } 
			end
						ib.unsubscribe sub_sdop , sub_ocd
					end.join
				else
					Connection.logger.error { "#{to_human} : using cached data" }
				end

			# -----------------------------------------------------------------------------------------------------
			# select values and assign to options
			#
			unless @option_chain_definition.blank? 
				requested_strikes =  if block_given?
															 ref_price = market_price if ref_price == :request
															 if ref_price.nil?
																 ref_price =	 @option_chain_definition[:strikes].min  +
																	 ( @option_chain_definition[:strikes].max -  
																		@option_chain_definition[:strikes].min ) / 2 
																 Connection.logger.error{  "#{to_human} :: market price not set – using midpoint of avaiable strikes instead: #{ref_price.to_f}" }
															 end
															 atm_strike = @option_chain_definition[:strikes].min_by { |x| (x - ref_price).abs }
															 the_grouped_strikes = @option_chain_definition[:strikes].group_by{|e| e <=> atm_strike}	
															 begin
																 the_strikes =		yield the_grouped_strikes
#																 puts "TheStrikes #{the_strikes}"
																 the_strikes.unshift atm_strike unless the_strikes.first == atm_strike	  # the first item is the atm-strike
																 the_strikes
															 rescue
																 Connection.logger.error "#{to_human} :: not enough strikes :#{@option_chain_definition[:strikes].map(&:to_f).join(',')} "
																 []
															 end
														 else
															 @option_chain_definition[:strikes]
														 end

				# third friday of a month
				monthly_expirations =  @option_chain_definition[:expirations].find_all{|y| (15..21).include? y.day }
#				puts @option_chain_definition.inspect
				option_prototype = -> ( ltd, strike ) do 
						IB::Option.new( symbol: symbol, 
													 exchange: @option_chain_definition[:exchange],
													 trading_class: @option_chain_definition[:trading_class],
													 multiplier: @option_chain_definition[:multiplier],
													 currency: currency,  
													 last_trading_day: ltd, 
													 strike: strike, 
													 right: right )
				end
				options_by_expiry = -> ( schema ) do
					# Array: [ mmyy -> Options] prepares for the correct conversion to a Hash
					Hash[  monthly_expirations.map do | l_t_d |
						[  l_t_d.strftime('%m%y').to_i , schema.map{ | strike | option_prototype[ l_t_d, strike ]}.compact ]
					end  ]                         # by Hash[ ]
				end
				options_by_strike = -> ( schema ) do
					Hash[ schema.map do | strike |
						[  strike ,   monthly_expirations.map{ | l_t_d | option_prototype[ l_t_d, strike ]}.compact ]
					end  ]                         # by Hash[ ]
				end

				if sort == :strike
					options_by_strike[ requested_strikes ] 
				else 
					options_by_expiry[ requested_strikes ] 
				end
			else
				Connection.logger.error "#{to_human} ::No Options available"
				nil # return_value
			end
		end  # def

		# return a set of AtTheMoneyOptions
		def atm_options ref_price: :request, right: :put
			option_chain(  right: right, ref_price: ref_price, sort: :expiry) do | chain |
								chain[0]
			end

				
			end

		# return   InTheMoneyOptions
		def itm_options count:  5, right: :put, ref_price: :request, sort: :strike
			option_chain(  right: right,  ref_price: ref_price, sort: sort ) do | chain |
					if right == :put
						above_market_price_strikes = chain[1][0..count-1]
					else
						below_market_price_strikes = chain[-1][-count..-1].reverse
				end # branch
			end
		end		# def

    # return OutOfTheMoneyOptions
		def otm_options count:  5,  right: :put, ref_price: :request, sort: :strike
			option_chain( right: right, ref_price: ref_price, sort: sort ) do | chain |
					if right == :put
						#			puts "Chain: #{chain}"
						below_market_price_strikes = chain[-1][-count..-1].reverse
					else
						above_market_price_strikes = chain[1][0..count-1]
					end
			end
		end

######################  private methods 

private

# Base method to verify a contract
# 
# if :thread is given, the method subscribes to messages, fires the request and returns the thread, that 
# receives the exit-condition-message
# 
# otherwise the method waits until the response form tws is processed
# 
# 
# if :update is true, the attributes of the Contract itself are apdated
# 
# otherwise the Contract is untouched
			def _verify thread: nil , update:,  &b # :nodoc:

			ib =  Connection.current
			# we generate a Request-Message-ID on the fly
			message_id = nil #1.times.inject([]) {|r| v = rand(200) until v and not r.include? v; r << v}.pop 			
			# define local vars which are updated within the query-block
			exitcondition, count , queried_contract = false, 0, nil

			# currently the tws-request is suppressed for bags and if the contract_detail-record is present
			tws_request_not_nessesary = bag? || contract_detail.is_a?( ContractDetail )

			if tws_request_not_nessesary
				yield self if block_given?
				count = 1
			else # subscribe to ib-messages and describe what to do
				a = ib.subscribe(:Alert, :ContractData,  :ContractDataEnd) do |msg| 
					case msg
					when Messages::Incoming::Alert
						if msg.code == 200 && msg.error_id == message_id
							ib.logger.error { "Not a valid Contract :: #{self.to_human} " }
							exitcondition = true
						end
					when Messages::Incoming::ContractData
						if msg.request_id.to_i == message_id
							# if multible contracts are present, all of them are assigned
							# Only the last contract is saved in self;  'count' is incremented
							count +=1
							## a specified block gets the contract_object on any uniq ContractData-Event
							if block_given?
								yield msg.contract
							elsif count > 1 
								queried_contract = msg.contract  # used by the logger (below) in case of mulible contracts
							end
							if update
								self.attributes = msg.contract.attributes
								self.contract_detail = msg.contract_detail unless msg.contract_detail.nil?
							end
						end
					when Messages::Incoming::ContractDataEnd
						exitcondition = true if msg.request_id.to_i ==  message_id

					end  # case
				end # subscribe

				### send the request !
				contract_to_be_queried =  con_id.present? ? self : query_contract  
				# if no con_id is present,  the given attributes are checked by query_contract
				if contract_to_be_queried.present?   # is nil if query_contract fails
					message_id = ib.send_message :RequestContractData, :contract => contract_to_be_queried 
					
					th =  Thread.new do
						begin
							Timeout::timeout(1) do
								loop{ break if exitcondition ; sleep 0.005 } 
							end
						rescue Timeout::Error
							Connection.logger.error{ "#{to_human} --> No ContractData recieved " }
						end
						ib.unsubscribe a
					end
					if thread.nil?
						th.join    # wait for the thread to finish
						count			 # return count
					else
						th			# return active thread
					end
				else
					ib.logger.error { "Not a valid Contract-spezification, #{self.to_human}" }
				end
			end
			end

# Generates an IB::Contract with the required attributes to retrieve a unique contract from the TWS
# 
# Background: If the tws is queried with a »complete« IB::Contract, it fails occacionally.
# So – even to update its contents, a defined subset of query-parameters  has to be used.
# 
# The required data-fields are stored in a yaml-file and fetched by #YmlFile.
# 
# If `con_id` is present, only `con_id` and `exchange` are transmitted to the tws.
# Otherwise a IB::Stock, IB::Option, IB::Future or IB::Forex-Object with necessary attributes
# to query the tws is build (and returned)
# 
# If Attributes are missing, an IB::VerifyError is fired,
# This can be trapped with 
#   rescue IB::VerifyError do ...
	
    def  query_contract( invalid_record: true )  # :nodoc:
      ## the yml presents symbol-entries
      ## these are converted to capitalized strings 
      # dont do anything if no sec-type is specified
      return unless sec_type.present?

      items_as_string = ->(i){i.map{|x,y| x.to_s.capitalize}.join(', ')}
      ## here we read the corresponding attributes of the specified contract 
      item_values = ->(i){ i.map{|x,y| self.send(x).presence || y }}
      ## and finally we create a attribute-hash to instantiate a new Contract
      ## to_h is present only after ruby 2.1.0
      item_attributehash = ->(i){ i.keys.zip(item_values[i]).to_h }
			nessesary_items = YAML.load_file(yml_file)[sec_type]
      ## now lets proceed, but only if no con_id is present
			if con_id.blank?
				if item_values[nessesary_items].any?( &:nil? ) 
					 raise VerifyError, "#{items_as_string[nessesary_items]} are needed to retrieve Contract,
																	got: #{item_values[nessesary_items].join(',')}"
				end
				Contract.build  item_attributehash[nessesary_items].merge(:sec_type=> sec_type)  # return this
			else   # its always possible, to retrieve a Contract if con_id and exchange are present 
				 Contract.new  con_id: con_id , :exchange => exchange.presence || item_attributehash[nessesary_items][:exchange].presence || 'SMART'				# return this
			end  # if 
    end # def
		end # class




end # module
