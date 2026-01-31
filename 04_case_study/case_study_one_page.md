Title: Stock Price Data Quality + Correlation Analysis (Python)

Objective
Analyze a company stock dataset to (1) clean and validate the data and (2) investigate relationships between Open vs Close and High vs Low prices to support trend understanding and decision-making. 

Dataset
Daily stock data with columns Date, Open, High, Low, Close, Volume, Name, covering a multi-year period. The dataset contained 3019 rows and 7 columns before cleaning. 

Tools
Python (pandas, numpy), matplotlib, seaborn, scipy/stats. 


Process
•	Imported CSV into pandas and inspected structure (head/info/describe). 
•	Converted Date to datetime format for consistency. 
•	Checked missing values: found 18 missing rows (~0.59%) and removed them. 
•	Checked duplicates: no duplicate rows found. 
•	Detected outliers using Z-score (threshold = 3) and treated outliers by replacing extreme values with the feature mean (Open/Close/High/Low). 
•	Performed correlation analysis with correlation matrix, heatmap, scatterplots, and trend visualization. 


Key Findings
•	Open and Close prices show extremely strong positive correlation (close to 1), indicating they move in the same direction. 
•	High and Low prices also show strong positive correlation, suggesting daily price ranges scale together. 
•	Trend plots show Open and Close follow a similar movement pattern over time, supporting stable directional behaviour in
the dataset. 


Recommendations
•	Monitor correlation/trend shifts over time; significant deviations may signal market changes or unusual events. 
•	Combine this analysis with external context (e.g., news/earnings events) for better interpretation of sudden pattern changes. 
