import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/darcula.dart';
import 'package:flutter_highlight/themes/dark.dart';

class StrategyCodeScreen extends StatelessWidget {
  const StrategyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var code = '''
import pandas as pd
import yfinance as yf
import os
import requests

def fetch_data(indicator, interval='annual', datatype='json'):
    api_key = os.getenv('ALPHA_VANTAGE_API_KEY')
    url = f"https://www.alphavantage.co/query?function={indicator}&interval={interval}&apikey={api_key}&datatype={datatype}"
    response = requests.get(url)
    data = response.json()
    if 'data' in data:
        records = data['data']
        df = pd.DataFrame(records)
        df['date'] = pd.to_datetime(df['date'])
        df['value'] = df['value'].astype(float)
        return df.set_index('date')
    else:
        raise ValueError(f"Unexpected data format from Alpha Vantage API for {indicator}")

def get_historical_data(tickers, start_date, end_date):
    data = yf.download(tickers, start=start_date, end=end_date)
    return data['Adj Close']

def calculate_indicators(data):
    indicators = pd.DataFrame(index=data.index)
    for ticker in data.columns:
        indicators[f'{ticker}_SMA50'] = data[ticker].rolling(window=50).mean()
        indicators[f'{ticker}_SMA200'] = data[ticker].rolling(window=200).mean()
        indicators[f'{ticker}_Return'] = data[ticker].pct_change().rolling(window=20).mean()
        indicators[f'{ticker}_Volatility'] = data[ticker].pct_change().rolling(window=20).std()
    return indicators

def generate_signals(data, indicators):
    signals, scores, total_score = {}, {}, 0
    for ticker in data.columns:
        sma_score = 1 if indicators[f'{ticker}_SMA50'].iloc[-1] > indicators[f'{ticker}_SMA200'].iloc[-1] else 0
        return_score = max(indicators[f'{ticker}_Return'].iloc[-1], 0)
        volatility_score = 1 / (indicators[f'{ticker}_Volatility'].iloc[-1] + 1)
        score = sma_score * 0.5 + return_score * 0.3 + volatility_score * 0.2
        scores[ticker] = score
        total_score += score
    for ticker in data.columns:
        signals[ticker] = int(round((scores[ticker] / total_score) * 100)) if total_score != 0 else 0
    remaining_allocation = 100 - sum(signals.values())
    if remaining_allocation != 0:
        sorted_tickers = sorted(signals, key=lambda x: scores[x], reverse=True)
        for i in range(abs(remaining_allocation)):
            signals[sorted_tickers[i % len(sorted_tickers)]] += 1 if remaining_allocation > 0 else -1
    return signals

def trading_strategy(start_date, end_date):
    tickers = ['NVDA', 'AMD', 'INTC']
    data = get_historical_data(tickers, start_date, end_date)
    indicators = calculate_indicators(data)
    signals = generate_signals(data, indicators)
    return signals, data

start_date = "2021-01-01"
end_date = pd.Timestamp.today().strftime('%Y-%m-%d')
signals, data = trading_strategy(start_date, end_date)

# Adjust cryptocurrency signals
signals = {k: v for k, v in signals.items()}

print(signals)
''';
    return Scaffold(
      body: SingleChildScrollView(
        child: HighlightView(
          code,
          language: 'python',
          theme: darculaTheme,
          padding: EdgeInsets.all(12),
        ),
      ),
    );
  }
}
