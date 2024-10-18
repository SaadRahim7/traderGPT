class Order {
  // Common properties
  String? filledAt;
  double? filledQty;
  double? qty;
  String? side;
  String? status;
  String? submittedAt;
  String? symbol;
  String? type;

  // Additional properties for Coinbase response
  String? attachedOrderConfiguration;
  String? attachedOrderId;
  String? averageFilledPrice;
  String? cancelMessage;
  String? clientOrderId;
  String? completionPercentage;
  String? createdTime;
  List<dynamic>? editHistory;
  String? fee;
  String? filledSize;
  String? filledValue;
  bool? isLiquidation;
  String? lastFillTime;
  String? leverage;
  String? marginType;
  String? numberOfFills;
  String? orderPlacementSource;
  String? originatingOrderId;
  String? outstandingHoldAmount;
  bool? pendingCancel;
  String? productId;
  String? productType;
  String? rejectMessage;
  String? rejectReason;
  String? retailPortfolioId;
  bool? settled;
  bool? sizeInQuote;
  bool? sizeInclusiveOfFees;
  String? timeInForce;
  String? totalFees;
  String? totalValueAfterFees;
  String? triggerStatus;
  String? userId;

  // Constructor
  Order({
    // Common properties
    this.filledAt,
    this.filledQty,
    this.qty,
    this.side,
    this.status,
    this.submittedAt,
    this.symbol,
    this.type,
    
    // Coinbase-specific properties
    this.attachedOrderConfiguration,
    this.attachedOrderId,
    this.averageFilledPrice,
    this.cancelMessage,
    this.clientOrderId,
    this.completionPercentage,
    this.createdTime,
    this.editHistory,
    this.fee,
    this.filledSize,
    this.filledValue,
    this.isLiquidation,
    this.lastFillTime,
    this.leverage,
    this.marginType,
    this.numberOfFills,
    this.orderPlacementSource,
    this.originatingOrderId,
    this.outstandingHoldAmount,
    this.pendingCancel,
    this.productId,
    this.productType,
    this.rejectMessage,
    this.rejectReason,
    this.retailPortfolioId,
    this.settled,
    this.sizeInQuote,
    this.sizeInclusiveOfFees,
    this.timeInForce,
    this.totalFees,
    this.totalValueAfterFees,
    this.triggerStatus,
    this.userId,
  });

  // Factory method to create an Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      // Common fields
      filledAt: json['filled_at'],
      filledQty: json['filled_qty']?.toDouble(),
      qty: json['qty']?.toDouble(),
      side: json['side'],
      status: json['status'],
      submittedAt: json['submitted_at'],
      symbol: json['symbol'],
      type: json['type'],

      // Coinbase-specific fields
      attachedOrderConfiguration: json['attached_order_configuration'],
      attachedOrderId: json['attached_order_id'],
      averageFilledPrice: json['average_filled_price'],
      cancelMessage: json['cancel_message'],
      clientOrderId: json['client_order_id'],
      completionPercentage: json['completion_percentage'],
      createdTime: json['created_time'],
      editHistory: json['edit_history'],
      fee: json['fee'],
      filledSize: json['filled_size'],
      filledValue: json['filled_value'],
      isLiquidation: json['is_liquidation'],
      lastFillTime: json['last_fill_time'],
      leverage: json['leverage'],
      marginType: json['margin_type'],
      numberOfFills: json['number_of_fills'],
      orderPlacementSource: json['order_placement_source'],
      originatingOrderId: json['originating_order_id'],
      outstandingHoldAmount: json['outstanding_hold_amount'],
      pendingCancel: json['pending_cancel'],
      productId: json['product_id'],
      productType: json['product_type'],
      rejectMessage: json['reject_message'],
      rejectReason: json['reject_reason'],
      retailPortfolioId: json['retail_portfolio_id'],
      settled: json['settled'],
      sizeInQuote: json['size_in_quote'],
      sizeInclusiveOfFees: json['size_inclusive_of_fees'],
      timeInForce: json['time_in_force'],
      totalFees: json['total_fees'],
      totalValueAfterFees: json['total_value_after_fees'],
      triggerStatus: json['trigger_status'],
      userId: json['user_id'],
    );
  }

  // Method to convert Order to JSON (optional, if needed)
  Map<String, dynamic> toJson() {
    return {
      // Common fields
      'filled_at': filledAt,
      'filled_qty': filledQty,
      'qty': qty,
      'side': side,
      'status': status,
      'submitted_at': submittedAt,
      'symbol': symbol,
      'type': type,

      // Coinbase-specific fields
      'attached_order_configuration': attachedOrderConfiguration,
      'attached_order_id': attachedOrderId,
      'average_filled_price': averageFilledPrice,
      'cancel_message': cancelMessage,
      'client_order_id': clientOrderId,
      'completion_percentage': completionPercentage,
      'created_time': createdTime,
      'edit_history': editHistory,
      'fee': fee,
      'filled_size': filledSize,
      'filled_value': filledValue,
      'is_liquidation': isLiquidation,
      'last_fill_time': lastFillTime,
      'leverage': leverage,
      'margin_type': marginType,
      'number_of_fills': numberOfFills,
      'order_placement_source': orderPlacementSource,
      'originating_order_id': originatingOrderId,
      'outstanding_hold_amount': outstandingHoldAmount,
      'pending_cancel': pendingCancel,
      'product_id': productId,
      'product_type': productType,
      'reject_message': rejectMessage,
      'reject_reason': rejectReason,
      'retail_portfolio_id': retailPortfolioId,
      'settled': settled,
      'size_in_quote': sizeInQuote,
      'size_inclusive_of_fees': sizeInclusiveOfFees,
      'time_in_force': timeInForce,
      'total_fees': totalFees,
      'total_value_after_fees': totalValueAfterFees,
      'trigger_status': triggerStatus,
      'user_id': userId,
    };
  }
}
