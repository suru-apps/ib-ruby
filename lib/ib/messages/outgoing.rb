require 'ib/messages/outgoing/abstract_message'

# TODO: Don't instantiate messages, use their classes as just namespace for .encode/decode

module IB
  module Messages

    # Outgoing IB messages (sent to TWS/Gateway)
    module Outgoing
      extend Messages # def_message macros

      ### Defining (short) Outgoing Message classes for IB:

      ## Empty messages (no data)

      # Request the open orders that were placed from THIS client. Each open order
      # will be fed back through the OpenOrder and OrderStatus messages ONCE.
      # NB: Client with a client_id of 0 will also receive the TWS-owned open orders.
      # These orders will be associated with the client and a new orderId will be
      # generated. This association will persist over multiple API and TWS sessions.
      RequestOpenOrders = def_message 5

      # Request the open orders placed from all clients and also from TWS. Each open
      # order will be fed back through the OpenOrder and OrderStatus messages ONCE.
      # Note this does not re-bind those Orders to requesting Client!
      # Use RequestAutoOpenOrders to request such re-binding.
      RequestAllOpenOrders = def_message 16

      # Request that newly created TWS orders be implicitly associated with this client.
      # When a new TWS order is created, the order will be associated with this client
      # and automatically fed back through the OpenOrder and OrderStatus messages.
      # It is a 'continuous' request such that it gets turned 'on' when called with a
      # TRUE auto_bind parameter. When it's called with FALSE auto_bind, new TWS orders
      # will not bind to this client going forward. Note that TWS orders can only be
      # bound to clients with a client_id of 0. TODO: how to properly test this?
      # data = { :auto_bind => boolean }
      RequestAutoOpenOrders = def_message 15, :auto_bind

      # Requests an XML document that describes the valid parameters that a scanner
      # subscription can have (for outgoing RequestScannerSubscription message).
      RequestScannerParameters = def_message 24

      CancelNewsBulletins = def_message 13
      RequestCurrentTime = def_message 49
      RequestGlobalCancel = def_message 58

      ## Data format is: @data = { :id => ticker_id}
      CancelMarketData = def_message [2, 2]
      CancelMarketDepth = def_message 11
      CancelScannerSubscription = def_message 23
      CancelHistoricalData = def_message 25
      CancelRealTimeBars = def_message 51

      ## Data format is: @data = { :id => request_id }
      CancelFundamentalData = def_message 53
      CancelCalculateImpliedVolatility = CancelImpliedVolatility = def_message(56)
      CancelCalculateOptionPrice = CancelOptionPrice = def_message(57)

      ## Data format is: @data ={ :id => local_id of order to cancel }
      CancelOrder = def_message 4

      # Request the next valid ID that can be used when placing an order. Responds with
      # NextValidId message, and the id returned is that next valid Id for orders.
      # That ID will reflect any autobinding that has occurred (which generates new
      # IDs and increments the next valid ID therein).
      # @data = { :number of ids requested => int } NB: :number option is ignored by TWS!
      RequestIds = def_message 8, [:number, 1]
      # data = { :all_messages => boolean }
      RequestNewsBulletins = def_message 12, :all_messages
      # data = { :log_level => int }
      SetServerLoglevel = def_message 14, :log_level
      # data = { :fa_data_type => int }
      RequestFA = def_message 18, :fa_data_type
      # data = { :fa_data_type => int, :xml => String }
      ReplaceFA = def_message 19, :fa_data_type, :xml
      # data = { :market_data_type => int }


      # data => { :id => request_id (int), :contract => Contract }
      #
      # Special case for options: "wildcards" in the Contract fields retrieve Option chains
      #   strike = 0 means all strikes
      #   right = "" meanns both call and put
      #   expiry = "" means all expiries
      #   expiry = "2013" means all expiries in 2013
      #   expiry = "201311" means all expiries in Nov 2013
      # You'll get several ContractData (10) messages back if there is more than one match.
      # When all the matches are delivered you'll get ContractDataEnd (52) message.
      RequestContractDetails = RequestContractData =
          def_message([9, 8],
                      [:contract, :serialize_long, [:sec_id_type]])

      # data = { :id => ticker_id (int), :contract => Contract, :num_rows => int }
      RequstMarketDepthExchanges =			# requires ServerVersion >= 112
		 	   def_message 82
      RequestMarketDepth = def_message([10, 5],
                                       [:contract, :serialize_short],
                                       :num_rows, 
				       "")  #  mktDataOptionsStr. ## not supported by api

      # When this message is sent, TWS responds with ExecutionData messages, each
      # containing the execution report that meets the specified criteria.
      # @data={:id =>         int: :request_id,
      #        :client_id => int: Filter the results based on the clientId.
      #        :acct_code => Filter the results based on based on account code.
      #                      Note: this is only relevant for Financial Advisor accts.
      #        :sec_type =>  Filter the results based on the order security type.
      #        :time =>      Filter the results based on execution reports received
      #                      after the specified time - format "yyyymmdd-hh:mm:ss"
      #        :symbol   =>  Filter the results based on the order symbol.
      #        :exchange =>  Filter the results based on the order exchange
      #        :side =>  Filter the results based on the order action: BUY/SELL/SSHORT
      RequestExecutions = def_message([7, 3],
                                      :client_id,
                                      :acct_code,
                                      :time, # Format "yyyymmdd-hh:mm:ss"
                                      :symbol,
                                      :sec_type,
                                      :exchange,
                                      :side)

      # data = { :id => ticker_id (int),
      #          :contract => IB::Contract,
      #          :exercise_action => int, 1 = exercise, 2 = lapse
      #          :exercise_quantity => int, The number of contracts to be exercised
      #          :account => string,
      #          :override => int: Specifies whether your setting will override the
      #                       system's natural action. For example, if your action
      #                       is "exercise" and the option is not in-the-money, by
      #                       natural action the option would not exercise. If you
      #                       have override set to "yes" the natural action would be
      #                       overridden and the out-of-the money option would be
      #                       exercised. Values are:
      #                              - 0 = do not override
      #                              - 1 = override
      ExerciseOptions = def_message([ 21, 2 ],  # request_id required
                                    [:contract, :serialize_short],
                                    :exercise_action,
                                    :exercise_quantity,
                                    :account,
                                    :override)


      # The API can receive frozen market data from Trader Workstation. Frozen market
      # data is the last data recorded in our system. During normal trading hours,
      # the API receives real-time market data. If you use this function, you are
      # telling TWS to automatically switch to frozen market data AFTER the close.
      # Then, before the opening of the next trading day, market data will automatically
      # switch back to real-time market data.
      # :market_data_type = 1 (:real_time) for real-time streaming, 2 (:frozen) for frozen market data
			#										= 3 (delayed) for delayed streaming , 4 (frozen_delayed)  for frozen delayed
      RequestMarketDataType =
          def_message 59, [:market_data_type,
                           lambda { |type| MARKET_DATA_TYPES.invert[type] || type }, []]

      # Send this message to receive Reuters global fundamental data. There must be
      # a subscription to Reuters Fundamental set up in Account Management before
      # you can receive this data.
      # data = { :id => int: :request_id,
      #          :contract => Contract,
      #          :report_type => String: one of the following:
      #                   'estimates' - Estimates
      #                   'finstat'   - Financial statements
      #                    'snapshot' - Summary   }a
					#                    ReportsFinSummary	Financial summary
#ReportsOwnership	Company's ownership (Can be large in size)
#ReportSnapshot	Company's financial overview
#ReportsFinStatements	Financial Statements
#RESC	Analyst Estimates
#CalendarReport	Company's calendar 
      RequestFundamentalData =
          def_message([52,2],
      #                :request_id, 
											 [:contract, :serialize, :primary_exchange],
                      :report_type,
											""  )

					# contract.serialize(:primary_exchange) => => ["", "AAPL", "OPT", "SMART", "", "USD", ""]a
					#												con_id, symbol, sec_type, exchange, primary_exchange, currency, loacl_symbol
					#
      # data = { :request_id => int, :contract => Contract,
      #          :option_price => double, :under_price => double }
			#

			RequestHeadTimeStamp = 
					def_message( [87,0], #	:request_id required
					[:contract, :serialize_short, [:primary_exchange,:include_expired] ],
					[:use_rth, 1 ],
					[:what_to_show, 'Trades' ],
					[:format_date, 2 ]  )

			CancelHeadTimeStamp =
					def_message [90,0 ], #:request_id required



			RequestHistogramData = 
					def_message( [88, 0], # request_id required
					[:contract, :serialize_short, [:primary_exchange,:include_expired] ],
					[:use_rth, 1 ],
					[:time_period ]   )

			CancelHistogramData =
					def_message [89,0 ], #:request_id

      RequestCalculateImpliedVolatility = CalculateImpliedVolatility =
          RequestImpliedVolatility =
              def_message([ 54,3 ],										# request_id required
                          [:contract, :serialize_long, []],
                          :option_price,
                          :under_price,
													[:implied_volatility_options_count, 0],
												  [:implied_volatility_options_conditions, ''])

      # data = { :request_id => int, :contract => Contract,
      #          :volatility => double, :under_price => double }
      RequestCalculateOptionPrice = CalculateOptionPrice = RequestOptionPrice =
          def_message([ 55, 3],										# request_id required
                      [:contract, :serialize_long, []],
                      :volatility,
                      :under_price,
													[:implied_volatility_options_count, 0],
												  [:implied_volatility_options_conditions, ''])

      # Start receiving market scanner results through the ScannerData messages.
      # @data = { :id => ticker_id (int),
      #  :number_of_rows => int: number of rows of data to return for a query.
      #  :instrument => The instrument type for the scan. Values include
      #                                'STK', - US stocks
      #                                'STOCK.HK' - Asian stocks
      #                                'STOCK.EU' - European stocks
      #  :location_code => Legal Values include:
      #                           - STK.US - US stocks
      #                           - STK.US.MAJOR - US stocks (without pink sheet)
      #                           - STK.US.MINOR - US stocks (only pink sheet)
      #                           - STK.HK.SEHK - Hong Kong stocks
      #                           - STK.HK.ASX - Australian Stocks
      #                           - STK.EU - European stocks
      #  :scan_code => The type of the scan, such as HIGH_OPT_VOLUME_PUT_CALL_RATIO.
      #  :above_price => double: Only contracts with a price above this value.
      #  :below_price => double: Only contracts with a price below this value.
      #  :above_volume => int: Only contracts with a volume above this value.
      #  :market_cap_above => double: Only contracts with a market cap above this
      #  :market_cap_below => double: Only contracts with a market cap below this value.
      #  :moody_rating_above => Only contracts with a Moody rating above this value.
      #  :moody_rating_below => Only contracts with a Moody rating below this value.
      #  :sp_rating_above => Only contracts with an S&P rating above this value.
      #  :sp_rating_below => Only contracts with an S&P rating below this value.
      #  :maturity_date_above => Only contracts with a maturity date later than this
      #  :maturity_date_below => Only contracts with a maturity date earlier than this
      #  :coupon_rate_above => double: Only contracts with a coupon rate above this
      #  :coupon_rate_below => double: Only contracts with a coupon rate below this
      #  :exclude_convertible => Exclude convertible bonds.
      #  :scanner_setting_pairs => Used with the scan_code to help further narrow your query.
      #                            Scanner Setting Pairs are delimited by slashes, making
      #                            this parameter open ended. Example is "Annual,true" -
      #                            when used with 'Top Option Implied Vol % Gainers' scan
      #                            would return annualized volatilities.
      #  :average_option_volume_above =>  int: Only contracts with average volume above this
      #  :stock_type_filter => Valid values are:
      #                          'ALL' (excludes nothing)
      #                          'STOCK' (excludes ETFs)
      #                          'ETF' (includes ETFs) }
      # ------------
      # To learn all valid parameter values that a scanner subscription can have,
      # first subscribe to ScannerParameters and send RequestScannerParameters message.
      # Available scanner parameters values will be listed in received XML document.
      RequestScannerSubscription =
          def_message([22, 3],
                      [:number_of_rows, -1], # was: EOL,
                      :instrument,
                      :location_code,
                      :scan_code,
                      :above_price,
                      :below_price,
                      :above_volume,
                      :market_cap_above,
                      :market_cap_below,
                      :moody_rating_above,
                      :moody_rating_below,
                      :sp_rating_above,
                      :sp_rating_below,
                      :maturity_date_above,
                      :maturity_date_below,
                      :coupon_rate_above,
                      :coupon_rate_below,
                      :exclude_convertible,
                      :average_option_volume_above, # ?
                      :scanner_setting_pairs,
                      :stock_type_filter)


										  
      require 'ib/messages/outgoing/place_order'
      require 'ib/messages/outgoing/bar_requests'
      require 'ib/messages/outgoing/account_requests'
      require 'ib/messages/outgoing/request_marketdata'

    end # module Outgoing
  end # module Messages
end # module IB

__END__
## python: message.py
     REQ_MKT_DATA                  = 1
     CANCEL_MKT_DATA               = 2
     PLACE_ORDER                   = 3
     CANCEL_ORDER                  = 4
     REQ_OPEN_ORDERS               = 5
     REQ_ACCT_DATA                 = 6
     REQ_EXECUTIONS                = 7
     REQ_IDS                       = 8
     REQ_CONTRACT_DATA             = 9
     REQ_MKT_DEPTH                 = 10
     CANCEL_MKT_DEPTH              = 11
     REQ_NEWS_BULLETINS            = 12
     CANCEL_NEWS_BULLETINS         = 13
     SET_SERVER_LOGLEVEL           = 14
     REQ_AUTO_OPEN_ORDERS          = 15
     REQ_ALL_OPEN_ORDERS           = 16
     REQ_MANAGED_ACCTS             = 17
     REQ_FA                        = 18
     REPLACE_FA                    = 19
     REQ_HISTORICAL_DATA           = 20
     EXERCISE_OPTIONS              = 21
     REQ_SCANNER_SUBSCRIPTION      = 22
     CANCEL_SCANNER_SUBSCRIPTION   = 23
     REQ_SCANNER_PARAMETERS        = 24
     CANCEL_HISTORICAL_DATA        = 25
     REQ_CURRENT_TIME              = 49
     REQ_REAL_TIME_BARS            = 50
     CANCEL_REAL_TIME_BARS         = 51
     REQ_FUNDAMENTAL_DATA          = 52
     CANCEL_FUNDAMENTAL_DATA       = 53
     REQ_CALC_IMPLIED_VOLAT        = 54
     REQ_CALC_OPTION_PRICE         = 55
     CANCEL_CALC_IMPLIED_VOLAT     = 56
     CANCEL_CALC_OPTION_PRICE      = 57
     REQ_GLOBAL_CANCEL             = 58
     REQ_MARKET_DATA_TYPE          = 59  

     --> supported by ib-ruby 0.94
     
     REQ_POSITIONS                 = 61   supported now
     REQ_ACCOUNT_SUMMARY           = 62   supported now

     CANCEL_ACCOUNT_SUMMARY        = 63   supported now

     CANCEL_POSITIONS              = 64   supported now
     VERIFY_REQUEST                = 65
     VERIFY_MESSAGE                = 66
     QUERY_DISPLAY_GROUPS          = 67
     SUBSCRIBE_TO_GROUP_EVENTS     = 68
     UPDATE_DISPLAY_GROUP          = 69
     UNSUBSCRIBE_FROM_GROUP_EVENTS = 70
     START_API                     = 71
     VERIFY_AND_AUTH_REQUEST       = 72
     VERIFY_AND_AUTH_MESSAGE       = 73
     REQ_POSITIONS_MULTI           = 74   supported now
     CANCEL_POSITIONS_MULTI        = 75   supported now

     REQ_ACCOUNT_UPDATES_MULTI     = 76   supported now

     CANCEL_ACCOUNT_UPDATES_MULTI  = 77   supported now

     REQ_SEC_DEF_OPT_PARAMS        = 78
     REQ_SOFT_DOLLAR_TIERS         = 79
     REQ_FAMILY_CODES              = 80
     REQ_MATCHING_SYMBOLS          = 81
     REQ_MKT_DEPTH_EXCHANGES       = 82
     REQ_SMART_COMPONENTS          = 83
     REQ_NEWS_ARTICLE              = 84
     REQ_NEWS_PROVIDERS            = 85
     REQ_HISTORICAL_NEWS           = 86
     REQ_HEAD_TIMESTAMP            = 87   supported now

     REQ_HISTOGRAM_DATA            = 88   supported now

     CANCEL_HISTOGRAM_DATA         = 89   supported now

     CANCEL_HEAD_TIMESTAMP         = 90   supported now

     REQ_MARKET_RULE               = 91
     REQ_PNL                       = 92
     CANCEL_PNL                    = 93
     REQ_PNL_SINGLE                = 94
     CANCEL_PNL_SINGLE             = 95
     REQ_HISTORICAL_TICKS          = 96
     REQ_TICK_BY_TICK_DATA         = 97
     CANCEL_TICK_BY_TICK_DATA      = 98

