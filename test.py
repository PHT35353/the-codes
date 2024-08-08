from entsoe import EntsoePandasClient
import pandas as pd
import streamlit as st
import matplotlib.pyplot as plt


API_TOKEN = '0464a296-1b5d-4be6-a037-b3414de630f8'
client = EntsoePandasClient(api_key=API_TOKEN)

def get_entsoe_data(start, end, country_code):
    start = pd.Timestamp(start, tz='Europe/Brussels')
    end = pd.Timestamp(end, tz='Europe/Brussels')
    data = client.query_day_ahead_prices(country_code, start=start, end=end)
    data = data.reset_index()
    data.columns = ['Time', 'Price_EUR_per_MWh']
    return data

def efficient_boiler(electricity_price, gas_price):
    if pd.isna(electricity_price):
        return 'Unknown'
    if electricity_price < gas_price / 1000:
        return 'E-boiler'
    else:
        return 'Gas-boiler'

def gas_price_calculation(efficient_boiler, price_EUR_per_MWh, gas_price):
    if pd.isna(price_EUR_per_MWh) or efficient_boiler == 'Unknown':
        return float('nan')
    elif efficient_boiler == 'E-boiler':
        return 0
    else:
        return gas_price

def calculate_costs(data, gas_price):
    data['Efficient_Boiler'] = data['Price_EUR_per_MWh'].apply(efficient_boiler, gas_price=gas_price)
    data['Gas_Price'] = data.apply(lambda row: gas_price_calculation(row['Efficient_Boiler'], row['Prijs_EUR_per_MWh'], gas_price), axis=1)
    return data

def plot_boiler_usage(data):
    fig, ax = plt.subplots()
    data['Time'] = pd.to_datetime(data['Time'])
    data.set_index('Time', inplace=True)
    data['Efficient_Boiler'].value_counts().plot(kind='bar', ax=ax)
    ax.set_title('Boiler Usage Over Time')
    ax.set_xlabel('Boiler Type')
    ax.set_ylabel('Count')
    return fig

def calculate_savings(data, gas_prijs):
    total_cost_gas = data['Price_EUR_per_MWh'].apply(lambda x: gas_prijs).sum()
    total_cost_mixed = data['Gas_Price'].sum()
    absolute_savings = total_cost_gas - total_cost_mixed
    percentage_savings = (absolute_savings / total_cost_gas) * 100
    return absolute_savings, percentage_savings

def main():
    st.title('Boiler Efficiency Analysis')
    
    st.sidebar.title('Settings')
    start_date = st.sidebar.date_input('Start date', pd.to_datetime('2024-01-01'))
    end_date = st.sidebar.date_input('End date', pd.to_datetime('2024-12-31'))
    country_code = st.sidebar.text_input('Country code', 'NL')
    gas_price = st.sidebar.number_input('Gas price per kWh', value=0.30/9.796)
    
    if st.sidebar.button('Get Data'):
        data = get_entsoe_data(start_date, end_date, country_code)
        st.write('Data Retrieved:', data.head())

        data = calculate_costs(data, gas_price)
        st.write('Processed Data:', data.head())
        
        fig = plot_boiler_usage(data)
        st.pyplot(fig)
        
        absolute_savings, percentage_savings = calculate_savings(data, gas_price)
        st.write(f'Absolute Savings: {absolute_savings:.2f} EUR')
        st.write(f'Percentage Savings: {percentage_savings:.2f}%')

if __name__ == '__main__':
    main()

 
