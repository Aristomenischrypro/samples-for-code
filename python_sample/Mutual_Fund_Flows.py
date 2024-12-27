#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Dec 23 18:00:17 2024

@author: aristomenischryssafesprogopoulos
"""


import os

###################
# Users adjust only the working directory (wd) #
###################
wd = "/Users/aristomenischryssafesprogopoulos/Desktop/code_sample/python_data"
file = wd + '\\Files\\'


os.chdir(wd)
print("Current Working Directory:", os.getcwd())
###################
# Import packages #
###################
import numpy as np
import pandas as pd
import os
import datetime as dt
import wrds
import gc
import matplotlib.pyplot as plt
import gzip
import pickle
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)


#Cutover date settings
cutDate = "2024/07/01" #cutoff date -- quarters ending before this date use TR and after this date use CRSP
cutDateEarly = "2023/07/01" #early date to get CRSP data so you can include lags
DL = True #True if you've already downloaded the WRDS data, false if you wnat to download new data
IncludeMixed = True # Toggle for whether to include domestic equity funds

conn = wrds.Connection(wrds_username='aristomenis', wrds_password='Ares746297!@')

###################
# Connect to WRDS #
###################
if not(DL):
    conn=wrds.Connection()
    conn.list_libraries()
    conn.list_tables(library='crsp_q_mutualfunds')

    
#####################################################
# Download fund information and tna and return data from WRDS #
#####################################################

if not(DL):
    #Fund names and basic info file: CRSP Quarterly Update Mutual Funds Fund Summary
    f_n = conn.raw_sql("""select cusip8, crsp_fundno, crsp_portno, crsp_cl_grp,  fund_name, ticker, ncusip, 
                       delist_cd, first_offer_dt, end_dt, dead_flag, merge_fundno, index_fund_flag
                            from crsp_q_mutualfunds.fund_hdr
                            where crsp_fundno is not null""", 
                         date_cols=['end_dt', 'first_offer_dt'])

    #Fund styles
    f_s = conn.raw_sql("""select crsp_fundno, begdt, enddt, crsp_obj_cd, si_obj_cd, accrual_fund, sales_restrict, 
                       wbrger_obj_cd, policy, lipper_class, lipper_obj_cd, lipper_asset_cd, lipper_tax_cd
                            from crsp_q_mutualfunds.fund_style
                            where crsp_fundno is not null""",
                      date_cols=['begdt', 'enddt'])

    #Fund fees
    f_f = conn.raw_sql("""select crsp_fundno, begdt, enddt, mgmt_fee, exp_ratio, turn_ratio, fiscal_yearend
                            from crsp_q_mutualfunds.fund_fees
                            where crsp_fundno is not null""", 
                         date_cols=['begdt', 'enddt', 'fiscal_yearend'])

    #Fund returns
    ret = conn.raw_sql("""select caldt, crsp_fundno, mtna, mret, mnav
                            from crsp_q_mutualfunds.monthly_tna_ret_nav
                            where crsp_fundno is not null""", 
                         date_cols=['caldt'])

    #Make fundno an integer
    for d in [f_n, f_s, f_f, ret]:
        d["crsp_fundno"] = d["crsp_fundno"].astype("int32")

    #note categorical data types
    f_n[["delist_cd", "index_fund_flag", "dead_flag"]] = f_n[["delist_cd", "index_fund_flag", "dead_flag"]].astype("category")
    f_s[['crsp_obj_cd', 'si_obj_cd', 'accrual_fund', 'sales_restrict', 'wbrger_obj_cd', 'policy', 'lipper_class', 'lipper_obj_cd', 
         'lipper_asset_cd', 'lipper_tax_cd']] = f_s[['crsp_obj_cd', 'si_obj_cd',
       'accrual_fund', 'sales_restrict', 'wbrger_obj_cd', 'policy', 'lipper_class', 'lipper_obj_cd',
       'lipper_asset_cd', 'lipper_tax_cd']].astype("category")
    
    open_file = gzip.open("flowdflist.gz", "wb")
    pickle.dump([f_n, f_s, f_f, ret], open_file)
    open_file.close()

conn.close()

open_file = gzip.open("flowdflist.gz", "rb")
f_n, f_s, f_f, ret = pickle.load(open_file)
open_file.close()



##########################################################################
# Flag likely index funds to differentiate them to the active funds                         #
##########################################################################
index_words = ["Index", "Ind", "Idx", "Indx", "Mkt", "Market", 
               "Composite", "S&P", "Russell", "Nasdaq", "Dow", "Jones",
               "Wilshire", "NYSE", "iShares", "SPDR", "HOLDRs", "ETF",
               "Exchange-Traded Fund", "PowerShares", "StreetTRACKS", 
               "100", "400", "500", "600", "1000", "1500", "2000", "3000", "5000"]


#Screening words from Dou Kogan Wou (for index funds filters)
f_n["index"] = (~f_n.index_fund_flag.isnull()) 
for i in index_words:
    f_n["index"] = f_n["index"] | f_n.fund_name.str.contains(i, case=False, na=False, regex=False)
    
#Do SP and DJ case sensitive or else you'll get lots of false positives
f_n["index"] = f_n["index"] | f_n.fund_name.str.contains("SP", case=True, na=False, regex=False)
f_n["index"] = f_n["index"] | f_n.fund_name.str.contains("DJ", case=True, na=False, regex=False)
    
print(f_n.head()) 



# Count the number of rows where 'index_fund_flag' is 'D'
index_d_count = f_n[f_n["index_fund_flag"] == 'D'].shape[0]
print(f"Number of rows where index_fund_flag == 'D': {index_d_count}")

# Count the number of rows where 'index' is True
index_true_count = f_n[f_n["index"] == True].shape[0]
print(f"Number of rows where index == True: {index_true_count}")

f_n = f_n[f_n["index_fund_flag"] != 'D']

# Group by crsp_fundno and count distinct index_fund_flag values
distinct_index_fund_flag_counts = f_n.groupby('crsp_fundno')['index_fund_flag'].nunique()
multiple_index_fund_flags = distinct_index_fund_flag_counts[distinct_index_fund_flag_counts > 1]
has_multiple_flags = not multiple_index_fund_flags.empty
print(f"Are there any crsp_fundno with more than one distinct index_fund_flag? {has_multiple_flags}")
if has_multiple_flags:
    print("crsp_fundno with multiple distinct index_fund_flag values:")
    print(multiple_index_fund_flags)
    
    
##########################################################################
# Check there are no duplicated observations (O found)                #
##########################################################################

#Find observations with same crsp_fundno during the same year and month
ret["mdt"] = ret["caldt"] + pd.offsets.MonthEnd(0) #add column for month end date
print(sum(ret.duplicated(["crsp_fundno", "mdt"])))
print(ret.head())
#Check fund class numbers
print(ret.loc[5].head(20)) # this should not be interpolated

ret_december = ret[ret['mdt'].dt.month == 12]
distinct_counts_december = ret_december.groupby('mdt')['mtna'].nunique().reset_index() # default excludes nan
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december['mdt'], distinct_counts_december['mtna'], marker='o')
plt.title('Distinct CRSP not nan mtna Count for December per mdt in ret')
plt.xlabel('Date (mdt)')
plt.ylabel('Number of Distinct CRSP mtna')
plt.grid(True)
plt.savefig('fund_classes_ret_dec.png')
plt.show()


ret_december = ret[ret['caldt'].dt.month == 12]
distinct_counts_december = ret_december.groupby('caldt')['crsp_fundno'].nunique().reset_index()
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december['caldt'], distinct_counts_december['crsp_fundno'], marker='o')

# Adding titles and labels
plt.title('Distinct CRSP Fundno Count for December per Caldt')
plt.xlabel('Date (Caldt)')
plt.ylabel('Number of Distinct CRSP Fundno')
plt.grid(True)
plt.savefig('fund_classes_monthly_tna_ret_nav.png')
plt.show()


# Filter for rows where the month is December and 'mtna' is not NaN
ret_december = ret[(ret['caldt'].dt.month == 12) & (ret['mtna'].notna())]
distinct_counts_december_mtna = ret_december.groupby('caldt')['mtna'].nunique().reset_index()
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december_mtna['caldt'], distinct_counts_december_mtna['mtna'], marker='o')
plt.title('Distinct MTNA Count for December per Caldt (Non-NaN Only)')
plt.xlabel('Date (Caldt)')
plt.ylabel('Number of Distinct MTNA (Non-NaN)')
plt.grid(True)
plt.savefig('fund_classes_monthly_mtna_december.png')
plt.show()

##########################################################################
# Check there are no duplicated observations, and remove incubation funds#
##########################################################################
#Remove any funds before beginning date
#To capture incubation funds in your dataset, you need to identify and isolate funds 
#that have performance data (like returns or assets under management) before their official first offer date.
ret = ret.join(f_n.set_index("crsp_fundno")[["first_offer_dt","index", "fund_name"]], on="crsp_fundno") #The DataFrame ret is joined with f_n to bring in first_offer_dt, index, and fund_name columns based on crsp_fundno.
filt = ret.first_offer_dt > ret.caldt
print("Share TNA removed because observed before fund beginning date: ", ret.loc[filt, "mtna"].sum()/ret.mtna.sum())
ret = ret[~filt].copy()
print("Share TNA removed because no name available: ", ret.loc[ret.fund_name.isnull(), "mtna"].sum()/ret.mtna.sum())
ret = ret[~ret.fund_name.isnull()].copy()
del ret["fund_name"]




#############################################
# Calculate adjusted returns by fund   #
#############################################
#Note: Expense ratios are stated in the data "as of the most recently completed fiscal year". 
#Turnover ratios are stated "for the 12 months ending on fiscal_yearend". If fiscal_yearend is 
#missing then its for the 12 months ending on the begdt
#This is strange because where both are present the fiscal_yearend almost always matches the end_dt, not the beg_dt
#So for both I use the 12 months ending on the year prior to fiscal_yearend, and then use the 12 months
#ending on the begdt if that doesn't work. for expense ratios I fill any missing observations with the closest available data


#Right now just expense ratio. Fairly sure this is right, but may want to check we shouldnt include 12b-1 
#(12b-1 fee is an annual marketing or distribution fee on a mutual fund. )
#Or management fee separately
#Definitions:
    #Expense ratio: Ratio of total investment that shareholders pay for the fund’s operating expenses, which include 12b-1 fees
    #Management fee (only available from 1998 onward) Management fee ($)/ Average Net Assets 
    #($) represented as % The fee is calculated using ratios based on the line items reported in the 
    #Statement of Operations.  The management fee can be offset by fee waivers and/or reimbursements which 
    #will make this  value differ from the contractual fees found in the prospectus.

####Reset indices for faster joining
ret.set_index("crsp_fundno", drop=True, inplace=True)
f_f.set_index("crsp_fundno", drop=True, inplace=True)
print(ret.head())
####Filter out nan returns

####Find the closest available expense ratio data
#Add the dates for which the expense and turn ratio data is supposed to apply
f_f['exp_end'] = f_f['fiscal_yearend'] #+ pd.tseries.offsets.DateOffset(months=-12)
f_f.loc[f_f.fiscal_yearend.isnull(), 'exp_end'] = f_f.loc[f_f.fiscal_yearend.isnull(), 'enddt'] #f_f.loc[f_f.fiscal_yearend.isnull(), 'begdt']
f_f['exp_beg'] = f_f['exp_end'] + pd.tseries.offsets.DateOffset(months=-12, days=1)
#Join all beginning and end dates and expense ratios onto the returns
cross = ret.join(f_f[['exp_beg', 'exp_end', 'exp_ratio']], how="outer")

#Add a column for the distance in time between the return observation and the fee observation (0 if its the same period)
cross['dist_after_end'] = cross['caldt'] - cross['exp_end']
cross['dist_before_beg'] = cross['exp_beg'] - cross['caldt']
del cross['exp_beg']
del cross['exp_end']


print(cross.head(10))
print(cross.index)
cross.to_pickle("cross_stage_initial.gz")
cross= pd.read_pickle("cross_stage_initial.gz")


#Distance is the max of the distance before beginning or after end
cross.rename(columns={"dist_after_end":"dist"}, inplace=True)
cross.loc[cross.dist<cross.dist_before_beg,"dist"] = cross.loc[cross.dist<cross.dist_before_beg,"dist_before_beg"]
del cross["dist_before_beg"]

cross.reset_index(inplace=True)
cross = cross.sort_values("dist").drop_duplicates(subset=['crsp_fundno', 'caldt'], ignore_index=False).sort_values(["crsp_fundno", "caldt"])

####Add back 1/12 of the closest expense ratio to returns
cross['m_exp'] = cross.exp_ratio/12
cross['mret_adj'] = cross.mret
cross.loc[~np.isnan(cross.m_exp), "mret_adj"] = cross.loc[~np.isnan(cross.m_exp), "mret_adj"] + cross.loc[~np.isnan(cross.m_exp), "m_exp"]

##Check how many funds you've filled in data for
print("Share of funds with expenses backfilled: ", sum(cross.dist> dt.timedelta(days=0))/cross.shape[0])
print("Share of funds with expenses backfilled more than 1 year: ", sum(cross.dist> dt.timedelta(days=365))/cross.shape[0])
print("Share of funds with no expense data: ", sum(np.isnan(cross.dist))/cross.shape[0])

print("Share of tna with expenses backfilled: ", np.nansum(cross.loc[(cross.dist> dt.timedelta(days=0)), "mtna"])/np.nansum(cross.mtna))
print("Share of tna with expenses backfilled more than 1 year: ", np.nansum(cross.loc[(cross.dist> dt.timedelta(days=365)), "mtna"])/np.nansum(cross.mtna))
print("Share of tna with no expense data: ", np.nansum(cross.loc[np.isnan(cross.dist), "mtna"])/np.nansum(cross.mtna))
gc.collect()

cross_december = cross[cross['caldt'].dt.month == 12]
distinct_counts_december = cross_december.groupby('caldt')['crsp_fundno'].nunique().reset_index()
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december['caldt'], distinct_counts_december['crsp_fundno'], marker='o')

# Adding titles and labels
plt.title('Distinct CRSP Fundno Count for December per Caldt')
plt.xlabel('Date (Caldt)')
plt.ylabel('Number of Distinct CRSP Fundno')
plt.grid(True)
plt.savefig('fund_classes_cross_tna_cross_nav.png')
plt.show()


# Filter for rows where the month is December and 'mtna' is not NaN
cross_december = cross[(cross['caldt'].dt.month == 12) & (cross['mtna'].notna())]
distinct_counts_december_mtna = cross_december.groupby('caldt')['mtna'].nunique().reset_index()
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december_mtna['caldt'], distinct_counts_december_mtna['mtna'], marker='o')
plt.title('Distinct MTNA Count for December per Caldt (Non-NaN Only)')
plt.xlabel('Date (Caldt)')
plt.ylabel('Number of Distinct MTNA (Non-NaN)')
plt.grid(True)
plt.savefig('fund_classes_cross_mtna_december.png')
plt.show()


cross.to_pickle("cross_before_inter.gz")
cross = pd.read_pickle("cross_before_inter.gz")





#################################################################################
# Interpolation  for monthly returns (4 months maximum)
#################################################################################
print(cross.head(10))

# Group by 'crsp_fundno' and find the min and max 'mdt' for each group
fund_date_ranges = cross.groupby('crsp_fundno')['mdt'].agg(['min', 'max'])
# Filter for funds with min 'mdt' before 1985 and max 'mdt' after 1995
filtered_funds = fund_date_ranges[
    (fund_date_ranges['min'] <= pd.to_datetime("1985-12-31")) & 
    (fund_date_ranges['max'] >= pd.to_datetime("1995-01-01"))
]
matching_fundnos = filtered_funds.index.tolist()[:10]
print("First 10 matching fund numbers:", matching_fundnos)
cross_toy = cross[cross['crsp_fundno'] == 13]
print(cross_toy.head())

def custom_interpolate_before_1991(group):
    # Sort by date within the group
    group = group.sort_values(by="mdt").reset_index(drop=True)
    
    for idx in range(len(group)):
        current_date = group.loc[idx, 'mdt']
        
        # Interpolate 'mtna' if it is NaN and the date is before or equal to 1991-01-01
        if pd.isna(group.loc[idx, 'mtna']) and current_date <= pd.to_datetime("1991-01-01"):
            # Find previous and next valid values within a 3-month range
            prev_rows = group[(group['mdt'] < current_date) & 
                              (group['mdt'] >= current_date - pd.DateOffset(months=3)) & 
                              group['mtna'].notna()]
            
            next_rows = group[(group['mdt'] > current_date) & 
                              (group['mdt'] <= current_date + pd.DateOffset(months=3)) & 
                              group['mtna'].notna()]

            # Take the most recent previous and the nearest next value
            if not prev_rows.empty and not next_rows.empty:
                prev_mtna = prev_rows.iloc[-1]['mtna']
                next_mtna = next_rows.iloc[0]['mtna']
                group.at[idx, 'mtna'] = (prev_mtna + next_mtna) / 2

    return group

# Reset index before sorting to avoid mixed indexing issues
cross_toy = cross_toy.reset_index(drop=True)
cross_toy.sort_values(['crsp_fundno', 'mdt'], inplace=True)
cross_interpolate_toy = cross_toy.groupby('crsp_fundno').apply(custom_interpolate_before_1991)
cross_interpolate_toy.reset_index(drop=True, inplace=True)
print(cross_interpolate_toy.head())

cross = cross.reset_index(drop=True)
cross.sort_values(['crsp_fundno', 'mdt'], inplace=True)
cross_interpolate = cross.groupby('crsp_fundno').apply(custom_interpolate_before_1991)
cross_interpolate.reset_index(drop=True, inplace=True)
print(cross_interpolate.head())


cross_interpolate.to_pickle("cross_interpolate_initial.gz")
cross = pd.read_pickle("cross_interpolate_initial.gz")
print(cross.head())


#################################################################################
# Calculate lag tna and monthly flows before mergers and liquidations   #
#################################################################################
#Drop leading observations with nan tna
cross = cross[cross.groupby("crsp_fundno").mtna.ffill().notna()].copy() #ffill -> forward fill
#Add lag tna
cross["mtna_l"] = cross.groupby("crsp_fundno").mtna.shift(1)
#Set lagged tna of first observation for a fundno to be 0, unless it's the first month in the dataset
firstdt = cross.mdt.min()
cross.loc[(~cross.duplicated("crsp_fundno")) & (cross.mdt != firstdt), "mtna_l"] = 0
cross.to_pickle("cross_stage_flows.gz")
print(cross.head())
print(cross.dtypes)

#pre-merger flows (not strictly needed)
cross["flow"] = (cross.mtna - cross.mtna_l*(1+cross.mret_adj))


########################################################################
# Set outflows of liquidated funds to be terminal TNA                  #
########################################################################
lastdt = max(cross.mdt) #last possible date (delete if after this)
#find the fundnos that are liquidated
l_fundnos = f_n[(f_n.delist_cd=="L") | (f_n.delist_cd=="L?")].crsp_fundno #all the old funds are delisted because of either mergers 
#Create a dataframe of the last available date & tna for each fundno
l_last_obs = cross[np.isin(cross.crsp_fundno, l_fundnos) & ~np.isnan(cross.mtna)].sort_values("caldt", ascending=False).drop_duplicates("crsp_fundno")
#Change it to be the month after the last observation date and add a field saying its liqudated and 0 out the tna and returns
liq_obs = l_last_obs[["crsp_fundno","mdt", "mtna"]].copy()
liq_obs["mdt"] = liq_obs.mdt + pd.offsets.MonthEnd(1) #Careful - run this once 
liq_obs["liquidated"] = 1
liq_obs["mtna_l"] = liq_obs.mtna
liq_obs["mtna"] = 0
liq_obs["mret_adj"] = 0
liq_obs["flow"] = -liq_obs.mtna_l

#If there's already observations on this date (with nan values for qtna), then add a tag to them in the main dataset to say it's liquidated
liq_obs.set_index(["crsp_fundno", "mdt"], inplace=True)
cross.set_index(["crsp_fundno", "mdt"], inplace=True)
liq_obs["in_data"] = liq_obs.index.isin(cross.index)
cross = cross.join(liq_obs.loc[liq_obs.in_data, "liquidated"])
cross.to_csv('crsp_cross_liquidated.csv', index=False)

#If there weren't any observations, and the last observation wasn't the last observation of the whole dataset, then add the liquidation observation in
liq_obs = liq_obs[(liq_obs.index.get_level_values(1)<= lastdt) & (liq_obs.in_data==False)]
cross = pd.concat([cross, liq_obs])

###0-out the TNA for all liquidated observations after the date of liquidation
#fill down the acquired status for all dates after the merger date
cross["liquidated"] = cross.sort_index(level=1).groupby(level=0).liquidated.ffill()
#0 out any data points after liquidation
cross.loc[cross.liquidated==1,"mtna"] = 0
cross.loc[(cross.liquidated==1) & np.isnan(cross.mret_adj), "mret_adj"] = 0 #0 out the returns so that you correctly report 100% outflows as opposed to NAN


##############################################################################################################################################################
# Catch any funds that have nonsense patterns of monthly returns and qtna, and replace the qret with 0 (essentially deleting the obseration)                 #
#############################################################################################################################################################
cross["mtnagrowth"] = (cross.mtna/ cross.mtna_l) - 1

# Condition: TNA growth less than ±20% and returns greater than ±100%
condition = (cross.mtnagrowth.abs() < 0.2) & (cross.mret_adj.abs() > 1)
num_condition = condition.sum()
total_rows = len(cross)
percentage = (num_condition / total_rows) * 100
print(f"Percentage of rows with the condition: {percentage:.2f}%")

# Condition: TNA growth less than ±20% and returns greater than ±100%
condition = (cross.mtnagrowth.abs()<.1) & (cross.mret_adj.abs()>.5)
num_condition = condition.sum()
total_rows = len(cross)
percentage = (num_condition / total_rows) * 100
print(f"Percentage of rows with the condition: {percentage:.2f}%")

#If their returns are more than 100% but tna change less than 20%
cross.loc[(cross.mtnagrowth.abs()<.2) & (cross.mret_adj.abs()>1), ["mret_adj", "mret"]] = 0
#If there rreturns are more than 50% but tna growth less than 10%
cross.loc[(cross.mtnagrowth.abs()<.1) & (cross.mret_adj.abs()>.5), ["mret_adj", "mret"]] = 0


########################################################################
# Estimate the date of mergers based on last NAV date and flow amount   #
########################################################################

##Create df of the acquired funds 
mset = f_n[(f_n.delist_cd=="M") &(~f_n.merge_fundno.isnull())].copy() #set of funds
#add on the tna data for the acquired fund
mset["end_mdt"] = mset["end_dt"] + pd.offsets.MonthEnd(0)
#mset = mset.join(cross["mtna"], on=["crsp_fundno", "end_mdt"])
#mset.rename(columns={"mtna":"mtna_acquired"}, inplace=True)
print(cross.head())



#find the last tna observation for each fund
lasttna = cross.loc[np.isin(cross.index.get_level_values(0), mset.crsp_fundno) & ~cross.mtna.isnull(),["mtna"]].groupby(level=0).tail(1)
#Add on the end_dt recorded in the delisting file (last NAV report date)
lasttna = lasttna.join(mset.set_index("crsp_fundno")[["end_mdt", "merge_fundno"]])
#If there's no end date recorded in the merger dataset, just use the last tna date
lasttna.loc[lasttna.end_mdt.isnull(),"end_mdt"] = lasttna.index.get_level_values(1)[lasttna.end_mdt.isnull()]
lasttna["gap"] = lasttna.end_mdt - lasttna.index.get_level_values(1)
#rename to mset
mset = lasttna
print(lasttna.tail())



#After checking a few observations, last tna date tends to work better than end_date, so we'll use that
#Add mtna observations to the main database for up to 5 months after the last mtna date (in case you match after the end)
for t in range(1,6):
    lasttna_plus = mset[["mtna"]].copy()
    lasttna_plus["mtna_l"] = lasttna_plus.mtna
    lasttna_plus["mret_adj"] = 0
    lasttna_plus.index = pd.MultiIndex.from_tuples([(x[0], x[1] +pd.offsets.MonthEnd(t)) for x in lasttna_plus.index])
    lasttna_plus.index.rename(mset.index.names, inplace=True)
    #If there is an observation (with nan mtna) in the cross file write over it
    crossinlasttna = cross.index.isin(lasttna_plus.index)
    idx = cross.loc[crossinlasttna].index
    lasttnaincross = lasttna_plus.index.isin(idx)
    cross.loc[idx, ["mtna", "mtna_l", "mret_adj"]] = lasttna_plus.loc[idx, ["mtna", "mtna_l", "mret_adj"]]
    #If there isn't, then append it to to the main dataframe
    # cross = cross.append(lasttna_plus[~lasttnaincross])
    cross = pd.concat([cross, lasttna_plus[~lasttnaincross]])

mset.reset_index(inplace=True)

##Loop through 1 month before to 5 months after the tna end date and calculate the resulting flows for each possibility
for t in range(-1,6):
    mset["mdt_test_" + str(t)] = mset.mdt + pd.offsets.MonthEnd(t)
    #Add on the acquired tna for the relevant month
    mset = mset.join(cross.mtna, on=["crsp_fundno", "mdt_test_" + str(t)], rsuffix="_acquired_"+str(t))
    #Add on the acquirer tna
    mset = mset.join(cross[["mtna", "mtna_l", "mret_adj"]], on=["merge_fundno", "mdt_test_" + str(t)], rsuffix="_acquirer")
    #Add on a column for the corrected flow (and the flows without corrections) and drop the rest
    #if the lag tna is 0 of the acquiror then divide by the non-lag tna to get a sense of relative flows
    mset["divisor"] = mset.mtna_l
    mset.loc[mset.mtna_l==0, "divisor"] = mset.loc[mset.mtna_l==0, "mtna_acquirer"]
    mset["flow_pct_"+str(t)] = (mset.mtna_acquirer - mset.mtna_l*(1+mset.mret_adj) - mset["mtna_acquired_"+str(t)])/mset.divisor
    mset["flow_preadj_pct_"+str(t)] = (mset.mtna_acquirer - mset.mtna_l*(1+mset.mret_adj))/mset.divisor
    mset.drop(["mtna_acquirer", "mtna_l", "mret_adj"], axis=1, inplace=True)    
    
#replace any infs with nans (only occurs when acquirer  tna are 0 and lag tna are 0, so can't be valid merger date)
mset.replace([np.inf, -np.inf], np.nan, inplace=True)
# print(mset.tail())

##Print and drop any where we haven't been able to match it to an acquiror in the relevant window
matched = (mset[["flow_pct_" + str(t) for t in range(-1,6)]].isnull().sum(axis=1) < len(range(-1,6)))
print("Share of acquired tna with no match to acquiror: ", mset.loc[(~matched),"mtna"].sum()/mset.mtna.sum())
mset = mset.loc[matched,:]

### Calculate how much adjusting for mergers changes the calculated flows in each monht
mset.loc[:,["flow_adj_"+str(t) for t in range(-1,6)]] = mset[[c for c in mset.columns if c[0:9]=="flow_pct_"]].abs().to_numpy() - mset[[c for c in mset.columns if c[0:9]=="flow_prea"]].abs().to_numpy()
mset["min_flow_adj"] = mset[["flow_adj_"+str(t) for t in range(-1,6)]].min(axis=1)

#Print and drop those where the flows are always higher without the merger
print("share of acquired tna dropped because there wasn't any month where it made acquiror flows lower: ", mset.loc[mset.min_flow_adj>0,"mtna"].sum()/mset.mtna.sum())
mset = mset.loc[mset.min_flow_adj<=0,:]

###Find the merger date that minimises flows
#Find the index of the month that decreases the absolute value of flows the most
mset["m_t"] = np.nanargmin(mset[[c for c in mset.columns if c[0:9]=="flow_adj_"]].to_numpy(), axis=1)-1
testmontharray = mset[["mdt_test_" + str(t) for t in range(-1,6)]].to_numpy()
testtnaarray = mset[["mtna_acquired_" + str(t) for t in range(-1,6)]].to_numpy()
mset["merge_mdt"] = testmontharray[np.arange(testmontharray.shape[0]) , (mset["m_t"]+1).to_numpy()] #pick out the right month using array indexing
mset["mtna_acquired"] = testtnaarray[np.arange(testtnaarray.shape[0]) , (mset["m_t"]+1).to_numpy()] #pick out the relevant acquired using array indexing


###Print the number of mergers where you still end up finding absolute flows in the acquiror of over 100% 
print("Share of mergers giving over 100% absolute flows in the acquiror: ", sum(abs(mset[[c for c in mset.columns if c[0:9]=="flow_pct_"]]).min(axis=1)>1)/mset.shape[0])

###Add the merged TNAs to the acquiror data
mset.set_index(["merge_fundno", "merge_mdt"], inplace=True)
mset.index.rename(cross.index.names, inplace=True)
mset.rename(columns={"crsp_fundno":"acquired_fundno"}, inplace=True)
cross = cross.join(mset[["mtna_acquired", "acquired_fundno"]], rsuffix="_dup")
mset.index.rename(["merge_fundno", "merge_mdt"], inplace=True)
mset.rename(columns={"acquired_fundno":"crsp_fundno"}, inplace=True)

###0-out the TNA for all acquiree observations after the merger date
#reset m index to be acquiree nos
mset = mset.reset_index().set_index(["crsp_fundno","merge_mdt"])
mset.index.rename(cross.index.names, inplace=True)
#add a column that's an indicator for being acquired and merge onto the matching fund and date in the full data set
mset["acquired"] = 1
cross = cross.join(mset["acquired"])
#Mark a negative merger adjustment on the date of merger for all the acquired funds (so that they don't show up as a big outflow)
cross.loc[(cross.acquired==1),"mtna_acquired"] = -cross.loc[(cross.acquired==1),"mtna"] 
#fill down the acquired status for all dates after the merger date
cross["acquired"] = cross.groupby(level=0).acquired.ffill() #.sort_index(level=1)
#0 out any data points after acquisition
cross.loc[cross.acquired==1,"mtna"] = 0
cross.loc[(cross.acquired==1) & cross.mret_adj.isnull(), "mret_adj"] = 0 #0 out the returns so that you correctly report 100% outflows as opposed to NAN
# Share of acquired tna with no match to acquiror:  0.0322585766044749
# share of acquired tna dropped because there wasn't any month where it made acquiror flows lower:  0.16030557344397697
# Share of mergers giving over 100% absolute flows in the acquiror:  0.020318299050135245
# print(mset.tail())

duplicates = cross.reset_index(drop=False)[cross.reset_index(drop=False).duplicated()]
print(f"Number of duplicate rows: {len(duplicates)}")
del duplicates
cross.to_pickle("cross_stage_prequarter.gz")
cross= pd.read_pickle("cross_stage_prequarter.gz")

########################################
# Calculate quarterly flows   - I start from here for the monthly data #
########################################
# Filter the DataFrame for crsp_fundno == 483 and mdt == '1992-12-31'
print(cross.xs((483, '1992-12-31'), level=['crsp_fundno', 'mdt']))

### Aggregate quarterly data
#Add quarters to main data set
cross = cross.sort_index() #make sure it's sorted by date
cross["q"] = cross.index.get_level_values(1) + pd.offsets.QuarterEnd(0)
cross = cross.reset_index(drop=False).set_index(["crsp_fundno", "q"])
#Group by quarter and fundno and take last available observation
qdata = cross[['caldt', 'mtna', 'mnav', 'dist', 'acquired_fundno', 'acquired','liquidated', 'index']].groupby(level=[0,1]).last()
qdata.rename(columns={"mtna":"qtna", "mnav":"qnav"}, inplace=True)
#Check how it works
print(qdata.xs((483, '1992-12-31'), level=['crsp_fundno', 'q']))


#Add on cumulative quarterly returns
qret_adj = ((cross.mret_adj+1)[~np.isnan(cross.mret_adj)]).groupby(level=[0,1]).prod()-1
qret = ((cross.mret+1)[~np.isnan(cross.mret)]).groupby(level=[0,1]).prod()-1
qret_adj.name = "qret_adj"
qret.name = "qret"
qdata = qdata.join(qret_adj).join(qret)
#Add on sum of tna acquired and expenses incurred
qdata[["qtna_acquired", "q_exp"]] = cross[["mtna_acquired", "m_exp"]].groupby(level=[0,1]).sum()

### Calculate quarterly flow
#lag quarterly assets
qdata["qtna_l"] = qdata.groupby(level=0).qtna.shift(1)
#Set lag tna of first observation to be 0
firstdt = qdata.index.get_level_values(1).min()
qdata.loc[(~qdata.index.get_level_values(0).duplicated()) & (qdata.index.get_level_values(1) != firstdt), "qtna_l"] = 0
#flows
qdata.loc[qdata.qtna_acquired.isnull(), "qtna_acquired"] = 0 #0 out the acquired mtna if it's blank
qdata["flow"] = (qdata.qtna - qdata.qtna_l*(1+qdata.qret_adj) - qdata.qtna_acquired)
qdata["flow_pct"] = qdata["flow"]/qdata.qtna_l


######################################################################
# Add on strategy datae           #
#######################################################################

qdata.rename(columns={'dist':'dist_from_exp_data'}, inplace=True)
print(f_s.tail())

####Reset indices for faster joining
f_s.set_index("crsp_fundno", drop=True, inplace=True)
qdata = qdata.reset_index(drop=False).set_index("crsp_fundno")
print(f_s.head())
print(qdata.head())

####Find the closest available strategy data
#Join all beginning and end dates and strategies (crsp code only)
qdata = qdata.join(f_s[["enddt", "begdt", "crsp_obj_cd"]], how="outer")
#Change any missing calendar dates (becuase you filled them in for liquidation or acquisition observations) to be qdate
qdata.loc[qdata.caldt.isnull(),"caldt"] = qdata.loc[qdata.caldt.isnull(),"q"]
#Add a column for the distance in time between the return observation and the fee observation (0 if its the same period)
qdata['dist_after_end'] = qdata['caldt'] - qdata['enddt']
qdata['dist_before_beg'] = qdata['begdt'] - qdata['caldt']
qdata['dist'] = qdata[['dist_after_end', 'dist_before_beg']].max(axis=1)
qdata.drop(columns=["dist_after_end", "dist_before_beg", "begdt", "enddt"], inplace=True)
# Store the original length before dropping duplicates
original_length = len(qdata)
#Keep the quarter-strategy combination observation where the quarter is closest to lying within the strategy
qdata = qdata.reset_index(drop=False).sort_values("dist").drop_duplicates(subset=['crsp_fundno', 'q'], ignore_index=True).set_index(["crsp_fundno", "q"], drop=True).sort_index()
# Store the new length after dropping duplicates
new_length = len(qdata)
# Calculate the number of rows dropped
rows_dropped = original_length - new_length
print(f"Number of rows dropped: {rows_dropped}")
qdata.rename(columns={'dist':'dist_from_strat_data'}, inplace=True)

qdata.to_pickle("qdata.gz")
qdata=pd.read_pickle("qdata.gz")


###############################################################################
# Drop index Funds (3749) - I just verify that D are dropped
###############################################################################
print(qdata.head())
qdata = qdata.reset_index()
print(qdata.head())
print(f_n.head())

# Merge qdata with f_n on 'crsp_fundno' and keep only 'index_fund_flag' from f_n
qdata = qdata.merge(
    f_n[['crsp_fundno', 'index_fund_flag']],
    on='crsp_fundno',
    how='left',
    indicator=True
)
# Report merging results
print(qdata['_merge'].value_counts())
print(qdata.head())

# Filter rows where index_fund_flag == 'D'
filtered_df = qdata[qdata['index_fund_flag'] == 'D']
distinct_count = filtered_df['crsp_fundno'].nunique()
print(f"Number of distinct crsp_fundno with index_fund_flag == 'D': {distinct_count}")
del filtered_df

print(qdata[qdata['crsp_fundno'] == 29950].head())

qdata_december = qdata[qdata['q'].dt.month == 12]
distinct_counts_december = qdata_december.groupby('q')['crsp_fundno'].nunique().reset_index()
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december['q'], distinct_counts_december['crsp_fundno'], marker='o')
plt.title('Distinct CRSP Fundno Count for December per Caldt in Qdata')
plt.xlabel('Date (Caldt)')
plt.ylabel('Number of Distinct CRSP Fundno')
plt.grid(True)
plt.savefig('fund_classes_qdata.png')
plt.show()


qdata_december = qdata[qdata['q'].dt.month == 12]
distinct_counts_december = qdata_december.groupby('q')['qtna'].nunique().reset_index() # default excludes nan
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december['q'], distinct_counts_december['qtna'], marker='o')
plt.title('Distinct CRSP not nan Qtna Count for December per Caldt in Qdata')
plt.xlabel('Date (Caldt)')
plt.ylabel('Number of Distinct CRSP qtna')
plt.grid(True)
plt.savefig('fund_classes_qdata_dec.png')
plt.show()



#########################################################################################
# Map crsp_fundno to WFCIN level for the pre cutoff data      #
#MFLINKS tables provide a reliable means to link CRSP Mutual Fund (MFDB) data that covers mutual fund performance, 
# expenses, and related information to equity holdings data in the Thomson Reuters Mutual Fund Ownership data (formerly known as the CDA S12 data).
# wficn: Wharton Financial Institution Center Number (WFICN), which is a unique and permanent fund portfolio identifier.
# Still waiting to gain access to the updated MFLink but I only lose 0.4% of observation nly for the c_flow (which is the post 2008)- Access
#########################################################################################


flow = qdata
flow = flow.reset_index(drop=False).set_index("crsp_fundno")
c_map = pd.read_sas("MFLink2024/mflink1.sas7bdat").astype("int32")
c_map2 = pd.read_sas("MFLink2024/mflink3.sas7bdat")[["crsp_fundno", "wficn"]].astype("int32") #mflink3? It is just the addition for the crsp_fundno wficn
print(c_map2.head(2))
print(c_map.head(2))
# This file is used in 2. Holding BUilder but I save it here fr SAS usage
t_map = pd.read_sas("MFLink2024\mflink2.sas7bdat")
print(t_map.head())
t_map.to_csv("MFLink2024/mflink2.csv", index=True)
# Find the minimum and maximum values of 'rdate'
min_rdate = t_map['rdate'].min()
max_rdate = t_map['rdate'].max()
print("Minimum rdate:", min_rdate)
print("Maximum rdate:", max_rdate)


#########################################################################################################################
# Understanding the 3 files as relating to each other and then map the files
#########################################################################################################################
# Merge c_map2 and c_map on 'wficn' to find common values - The intersection should be empty
common_wficn = pd.merge(c_map2, c_map, on='wficn', how='inner', indicator=True)
all_nan_common = common_wficn['wficn'].isna().all()
print("Are all common 'wficn' values NaN in c_map2 and c_map?", all_nan_common)
print("Common 'wficn' values between c_map2 and c_map (if any):")
print(common_wficn)

# Find values in t_map that are not in c_map2 or c_map: Again this should be empty data
wficn_c_map2 = c_map2['wficn'].dropna().unique()
wficn_c_map = c_map['wficn'].dropna().unique()
wficn_t_map = t_map['wficn'].dropna().unique()
unique_in_t_map = set(wficn_t_map) - set(wficn_c_map2) - set(wficn_c_map)
print("Unique non-NaN 'wficn' values in t_map that are not in c_map2 or c_map:")
print(unique_in_t_map)


# Count unique values in c_map2 and c_map that are not in t_map
# So we have 40% that have a mapping crsp_fundno   wficn but no fundno wficn mapping (this is going to be a problem for the holdings)
unique_in_c_map2_count = len(set(wficn_c_map2) - set(wficn_t_map))
unique_in_c_map_count = len(set(wficn_c_map) - set(wficn_t_map))
print("Percentage of unique non-NaN 'wficn' values in c_map2 that are not in t_map:", unique_in_c_map2_count/len(c_map2) )
print("Percentage of unique non-NaN 'wficn' values in c_map that are not in t_map:", unique_in_c_map_count/ len(c_map))

### Final c_map concatenated
c_map = pd.concat([c_map, c_map2]).drop_duplicates()
c_map = c_map.reset_index(drop=True).set_index(["crsp_fundno"])
c_map.to_csv("MFLink2024/mflink1_3.csv", index=True)
print(c_map.head(2))
c_map.to_stata(file + 'c_map.dta')
filtered_df = c_map[c_map['wficn'] == 100001]


#Map the pre 2008 data to wficn portfolios using by default the index crsp_fundno
t_flow = flow.loc[(flow.q<cutDate),:].join(c_map)
#drop any with blank wficn
print("Share of tna dropped due to no matching WFICN: ", t_flow.loc[t_flow.wficn.isnull(),"qtna"].sum()/t_flow.qtna.sum())
# Share of tna dropped due to no matching WFICN:  0.30959594055341655 - 
# when cutdate is 2024 Share of tna dropped due to no matching WFICN:  0.2679074259745009
t_flow = t_flow.loc[~t_flow.wficn.isnull(),:]
t_flow["wficn"] = t_flow["wficn"].astype("int32")
t_flow_copy = t_flow.copy()
t_flow_copy.replace([np.inf, -np.inf], np.nan, inplace=True)
# Convert timedelta64[ns] columns to a numeric format (e.g., total days)
for col in t_flow_copy.select_dtypes(include=[np.dtype('timedelta64[ns]')]).columns:
    t_flow_copy[col] = t_flow_copy[col].dt.days  
t_flow_copy['index'] = t_flow_copy['index'].astype(str)
t_flow_copy.to_stata(file + 't_flow_wficn_fundno.dta')
print(t_flow.head())




t_flow_december = t_flow[t_flow['q'].dt.month == 12]
distinct_counts_december = t_flow_december.groupby('q')['qtna'].nunique().reset_index() # default excludes nan
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december['q'], distinct_counts_december['qtna'], marker='o')
plt.title('Distinct TR not nan Qtna Count for December T_FLOW')
plt.xlabel('Date (Caldt)')
plt.ylabel('Number of Distinct TR qtna')
plt.grid(True)
plt.savefig('fund_classes_TRMAP_dec.png')
plt.show()




#########################################################################################
# Map crsp_fund to crsp_portfolio (post 2011) and WFCIN level (pre 2011)  - Robert says that but 
# cutDate = "2008/07/01" #cutoff date -- quarters ending before this date use TR and after this date use CRSP
# cutDateEarly = "2007/07/01" #early date to get CRSP data so you can include lags    #
#########################################################################################
c_portmap = pd.read_pickle("crsp_fundno_portid_map.gz")
# so the mapping from fundno to port_id is 1-1 not dependent on time!
c_map= pd.read_stata(file + 'c_map.dta')
print(c_map.head())
print(c_map[c_map['crsp_fundno'] == 35183]) 
# In the wficn mapping I have double entries
print(c_portmap.head())
filtered_df = c_portmap[c_portmap['port_id'] == 100330]


#Join onto post 2008 data (all matching portnos with all beginning and end dates)
c_flow = flow.loc[(flow.q>=cutDateEarly),:].join(c_portmap)
print("Share of tna dropped due to no matching portno: ", c_flow.loc[c_flow.port_id.isnull(),"qtna"].sum()/c_flow.qtna.sum())
# Share of tna dropped due to no matching portno:  0.483775180846116
c_flow = c_flow.loc[~c_flow.port_id.isnull(),:]
c_flow_copy = c_flow.copy()
c_flow_copy["port_id"] = c_flow_copy["port_id"].astype("int32")
c_flow_copy['index'] = c_flow_copy['index'].astype(str)


c_flow_december = c_flow[c_flow['caldt'].dt.month == 12]
distinct_counts_december = c_flow_december.groupby('caldt')['qtna'].nunique().reset_index() # default excludes nan
plt.figure(figsize=(10, 6))
plt.plot(distinct_counts_december['caldt'], distinct_counts_december['qtna'], marker='o')
# Adding titles and labels
plt.title('Distinct CRSP not nan Qtna Count for caldt T_FLOW')
plt.xlabel('Date (Caldt)')
plt.ylabel('Number of Distinct CRSP qtna')
plt.grid(True)
plt.savefig('fund_classes_CRSPMAP_dec.png')
plt.show()

print(t_flow.head())
print(c_flow.head())

t_flow.to_pickle("t_flow_portid.gz")
c_flow.to_pickle("c_flow_portid.gz")



c_flow = pd.read_pickle("c_flow_portid.gz")
t_flow = pd.read_pickle("t_flow_portid.gz")


##########################################
# Aggregate flow data by mutual fund (granular level fund share)       #
##########################################

##Function to aggregate either section of the flows to portfolio level (and drop na flows) (once they're grouped by the relevant portfolio category)
def portag(flow):
    #Drop any nan flows
    flow = flow.loc[~flow.flow.isnull(),:].copy()
    
    #Sum up tna
    flow_p = flow[['flow', 'qtna', 'qtna_acquired']].groupby(level=[0,1]).sum().copy()
    
    #Recalculate lag qtna (in case funds dropped in/out of portfolio (unlikely))
    flow_p["q_l"] = flow_p.index.get_level_values(1)
    flow_p[["qtna_l", "q_l"]] = flow_p[["qtna", "q_l"]].groupby(level=0).shift(1)
    
    #Set lag tna of first observation to be 0
    firstdt = flow_p.index.get_level_values(1).min()
    flow_p.loc[(~flow_p.index.get_level_values(0).duplicated()) & (flow_p.index.get_level_values(1)!=firstdt), "qtna_l"] = 0

    #weighted average of returns and expenses
    for col in ['qret_adj', 'qret', 'q_exp']:
        flow[col+"_wt"] = flow[col] * flow['qtna_l']
        flow_p[col] = flow[col+"_wt"].groupby(level=[0,1]).sum() / flow_p["qtna_l"]
    
        #weight by current tna if lag tna are all 0
        flow[col+"_wt_alt"] = flow[col] * flow['qtna']
        flow_p.loc[(flow_p["qtna_l"]==0), col] = (flow[col+"_wt_alt"].groupby(level=[0,1]).sum() / flow_p["qtna"])[(flow_p["qtna_l"]==0)]

    #Just take the first value (sorted by size) for investment codes
    flow_p[['crsp_obj_cd', 'index']] = flow.sort_values("qtna", ascending=False)[['crsp_obj_cd','index']].groupby(level=[0,1]).first()
    
    #Recalculate flow based on the new qtna etc
    #flow_p["flow_alt"] = flow_p.flow
    flow_p["flow"] = (flow_p.qtna - flow_p.qtna_l*(1+flow_p.qret_adj) - flow_p.qtna_acquired)
    flow_p["flow_pct"] = flow_p["flow"]/flow_p.qtna_l
    
    return flow_p

#aggregate CRSP-period flows - Now port_id the index
c_flow = c_flow.reset_index().set_index(["port_id","q"])
# Before applying the portag() function, group crsp_fundno by port_id and q
crsp_fundno_mapping = c_flow.groupby(['port_id', 'q'])['crsp_fundno'].apply(list).reset_index()
# Apply the portag function
c_flow_ppp = portag(c_flow)
# Merge the crsp_fundno lists back into the aggregated dataframe
c_flow_ppp = c_flow_ppp.reset_index().merge(crsp_fundno_mapping, on=['port_id', 'q'], how='left').set_index(['port_id', 'q'])
# Print the result
print(c_flow_ppp.tail())
#c_flow_p = portag(c_flow) without having the funds merged it is the same 
#Aggreage TR-period flows
t_flow = t_flow.reset_index().set_index(["wficn","q"])
print(t_flow.head())
# Before applying the portag() function, group crsp_fundno by port_id and q
crsp_fundno_mapping_t = t_flow.groupby(['wficn', 'q'])['crsp_fundno'].apply(list).reset_index()
# Apply the portag function
t_flow_ppp = portag(t_flow)
# Merge the crsp_fundno lists back into the aggregated dataframe
t_flow_ppp = t_flow_ppp.reset_index().merge(crsp_fundno_mapping_t, on=['wficn', 'q'], how='left').set_index(['wficn', 'q'])
# Print the result
print(t_flow_ppp.head())
gc.collect()




c_flow_ppp.to_pickle("c_flow_ppp_pre.gz")
t_flow_ppp.to_pickle("t_flow_ppp_pre.gz")



# Print the results
print(t_flow_ppp.index.get_level_values(1).min())
print(t_flow_ppp.index.get_level_values(1).max())


# Print the results
print(c_flow_ppp.index.get_level_values(1).min())
print(c_flow_ppp.index.get_level_values(1).max())

#########################################################################################
# CLEANING STARTS
#########################################################################################
#######Drop portfolios that have a strategy code that isn't domestic equity
# CRSP STYLE CODE
# The CRSP US Survivor-Bias-Free Mutual Funds database includes style and objective codes from three different sources over
# the life of the database.  No single source exists for its full-time range. 
# • Wiesenberger Objective codes are populated between 1962 – 1993.
# • Strategic Insight Objective codes are populated between 1993 – 1998.
# • Lipper Objective codes begin 1998.
# The CRSP Style Code builds continuity within the database by using the three afore mentioned codes as its base and provides
# consistency with those codes provided by our different sources.
# The CRSP Style Code consists of up to four characters, with each position defined.  Reading Left to Right, the four codes
# represent an increasing level of granularity.  For example, a code for a particular mutual fund is EDYG, where:
# E = Equity, D = Domestic, Y = Style, G = Growth
# Codes with less than four characters exist, and it simply means that they are defined to a less granular level.
#########################################################################################


if IncludeMixed:
    t_codelook = (t_flow_ppp.crsp_obj_cd.str[0:2]=="ED") | t_flow_ppp.crsp_obj_cd.isnull() | (t_flow_ppp.crsp_obj_cd.str[0:1]=="M")
    c_codelook = (c_flow_ppp.crsp_obj_cd.str[0:2]=="ED") | c_flow_ppp.crsp_obj_cd.isnull() | (c_flow_ppp.crsp_obj_cd.str[0:1]=="M")
else:
    t_codelook = (t_flow_ppp.crsp_obj_cd.str[0:2]=="ED") | (t_flow_ppp.crsp_obj_cd.isnull())
    c_codelook = (c_flow_ppp.crsp_obj_cd.str[0:2]=="ED") | (c_flow_ppp.crsp_obj_cd.isnull())

print("Share of pre 08 qtna dropped because not domestic equity: ", t_flow_ppp.loc[~t_codelook,"qtna"].sum()/t_flow_ppp.qtna.sum())
print("Share of post 08 qtna dropped because not domestic equity: ", c_flow_ppp.loc[~c_codelook,"qtna"].sum()/c_flow_ppp.qtna.sum())
t_flow_ppp = t_flow_ppp.loc[t_codelook, :]
c_flow_ppp = c_flow_ppp.loc[c_codelook, :]


exclude_list = ["EDYH", "EDYI", "EDYS"]
if IncludeMixed:
    t_codelook = (((t_flow_ppp.crsp_obj_cd.str[0:2] == "ED") | t_flow_ppp.crsp_obj_cd.isnull() | (t_flow_ppp.crsp_obj_cd.str[0:1] == "M"))
    & ~t_flow_ppp.crsp_obj_cd.isin(exclude_list))
    c_codelook = (((c_flow_ppp.crsp_obj_cd.str[0:2] == "ED") | c_flow_ppp.crsp_obj_cd.isnull() | (c_flow_ppp.crsp_obj_cd.str[0:1] == "M"))
    & ~c_flow_ppp.crsp_obj_cd.isin(exclude_list))
else:
    t_codelook = (t_flow_ppp.crsp_obj_cd.str[0:2]=="ED") | (t_flow_ppp.crsp_obj_cd.isnull())
    c_codelook = (c_flow_ppp.crsp_obj_cd.str[0:2]=="ED") | (c_flow_ppp.crsp_obj_cd.isnull())
print("Share of pre 08 qtna dropped because domestic equity but not in the strategies we want: ", t_flow_ppp.loc[~t_codelook,"qtna"].sum()/t_flow_ppp.qtna.sum())
print("Share of post 08 qtna dropped because because domestic equity but not in the strategies we want: ", c_flow_ppp.loc[~c_codelook,"qtna"].sum()/c_flow_ppp.qtna.sum())
t_flow_ppp = t_flow_ppp.loc[t_codelook, :]
c_flow_ppp = c_flow_ppp.loc[c_codelook, :]


#Report Share of flows that are coming from observations with 1 MM in tna at start of period and 10x flows
print(t_flow_ppp.loc[(t_flow_ppp.qtna_l>1) & (t_flow_ppp.flow_pct.abs()>10), "flow"].abs().sum()/t_flow_ppp.flow.abs().sum())
print(c_flow_ppp.loc[(c_flow_ppp.qtna_l>1) & (c_flow_ppp.flow_pct.abs()>10), "flow"].abs().sum()/c_flow_ppp.flow.abs().sum())


c_flow_ppp.to_pickle("c_flow_ppp_afterioc.gz")
t_flow_ppp.to_pickle("t_flow_ppp_afterioc.gz")


c_flow_ppp = pd.read_pickle("c_flow_ppp_afterioc.gz")
t_flow_ppp = pd.read_pickle("t_flow_ppp_afterioc.gz")

#########################################################################################
# Drop portfolios that have sudden large flows (double or halve) that reverse within a year      #
#########################################################################################
#Identify problematic seeming flows (halve/double followed by reversal within a year)
c_flow_ppp.sort_index(ascending=False, inplace=True)
c_flow_ppp["maxnext4"] = c_flow_ppp.flow_pct.groupby(level=0).transform(lambda x: x.rolling(4).max())
c_flow_ppp["minnext4"] = c_flow_ppp.flow_pct.groupby(level=0).transform(lambda x: x.rolling(4).min())
c_flow_ppp.sort_index(inplace=True)
c_flow_ppp["maxlast4"] = c_flow_ppp.flow_pct.groupby(level=0).transform(lambda x: x.rolling(4).max())
c_flow_ppp["minlast4"] = c_flow_ppp.flow_pct.groupby(level=0).transform(lambda x: x.rolling(4).min())
c_infl_rev = ((c_flow_ppp["flow_pct"]>1) & (c_flow_ppp.qtna_l!=0) & ((c_flow_ppp.minnext4<-0.5) | (c_flow_ppp.minlast4<-0.5)))
c_outfl_rev = ((c_flow_ppp["flow_pct"]<-.5) & (c_flow_ppp.qtna!=0) & ((c_flow_ppp.maxnext4>1) | (c_flow_ppp.maxlast4>1)))
c_probports = c_flow_ppp[c_infl_rev | c_outfl_rev].index.get_level_values(0).unique()

c_goodports = c_flow_ppp.index.get_level_values(0).unique()[~np.isin(c_flow_ppp.index.get_level_values(0).unique(), c_probports)]
c_dropsize = c_flow_ppp.loc[c_probports, "qtna"].sum()/c_flow_ppp.qtna.sum()
print("CRSP dropped because of reversals: ", c_dropsize)
c_flow_ppp = c_flow_ppp.loc[c_goodports].copy()

t_flow_ppp.sort_index(ascending=False, inplace=True)
t_flow_ppp["maxnext4"] = t_flow_ppp.flow_pct.groupby(level=0).transform(lambda x: x.rolling(4).max())
t_flow_ppp["minnext4"] = t_flow_ppp.flow_pct.groupby(level=0).transform(lambda x: x.rolling(4).min())
t_flow_ppp.sort_index(inplace=True)
t_flow_ppp["maxlast4"] = t_flow_ppp.flow_pct.groupby(level=0).transform(lambda x: x.rolling(4).max())
t_flow_ppp["minlast4"] = t_flow_ppp.flow_pct.groupby(level=0).transform(lambda x: x.rolling(4).min())
t_infl_rev = ((t_flow_ppp["flow_pct"]>1) & (t_flow_ppp.qtna_l!=0) & ((t_flow_ppp.minnext4<-0.5) | (t_flow_ppp.minlast4<-0.5)))
t_outfl_rev = ((t_flow_ppp["flow_pct"]<-.5) & (t_flow_ppp.qtna!=0) & ((t_flow_ppp.maxnext4>1) | (t_flow_ppp.maxlast4>1)))
t_probports = t_flow_ppp[t_infl_rev | t_outfl_rev].index.get_level_values(0).unique()

t_goodports = t_flow_ppp.index.get_level_values(0).unique()[~np.isin(t_flow_ppp.index.get_level_values(0).unique(), t_probports)]
t_dropsize = t_flow_ppp.loc[t_probports, "qtna"].sum()/t_flow_ppp.qtna.sum()
print("TR dropped because of reversals: ", t_dropsize)
t_flow_ppp = t_flow_ppp.loc[t_goodports].copy()

for c in ["maxnext4", "minnext4", "maxlast4", "minlast4"]:
    del c_flow_ppp[c]
    del t_flow_ppp[c]

#Trim away pre 1980 data or post 2024 and the boundaries between the files 
c_flow_ppp = c_flow_ppp[(c_flow_ppp.index.get_level_values(1) >= cutDate) & (c_flow_ppp.index.get_level_values(1) < "2026/01/01")].copy()
t_flow_ppp = t_flow_ppp[(t_flow_ppp.index.get_level_values(1) > "1979/12/31") & (t_flow_ppp.index.get_level_values(1) < cutDate)].copy()


# Print the results
print(t_flow_ppp.index.get_level_values(1).min())
print(t_flow_ppp.index.get_level_values(1).max())
print(c_flow_ppp.index.get_level_values(1).min())
print(c_flow_ppp.index.get_level_values(1).max())
#Save
c_flow_ppp.index.rename(["port_id", "q"], inplace=True)
t_flow_ppp.index.rename(["port_id", "q"], inplace=True)

c_flow_ppp.to_pickle("Post08_port_flows_fund.gz")
t_flow_ppp.to_pickle("Pre08_port_flows_fund.gz")



c_flow_ppp = pd.read_pickle("Post08_port_flows_fund.gz")
t_flow_ppp = pd.read_pickle("Pre08_port_flows_fund.gz")

distinct_q_values = sorted(t_flow_ppp.index.get_level_values(1).unique())
# Display the sorted distinct values of 'q'
print(distinct_q_values)
distinct_q_values = sorted(c_flow_ppp.index.get_level_values(1).unique())
# Display the sorted distinct values of 'q'
print(distinct_q_values)


################################################################################################################################
#Cleaned Data Summary
################################################################################################################################
#Save
joint = pd.concat([c_flow_ppp, t_flow_ppp])
print(joint.head())
# Extract all distinct values of 'q' from level 1 of the multiindex and sort them
distinct_q_values = sorted(joint.index.get_level_values(1).unique())
# Display the sorted distinct values of 'q'
print(distinct_q_values)

# Replace infinity and -infinity with NaN in the entire DataFrame
joint.replace([np.inf, -np.inf], np.nan, inplace=True)
# Convert the boolean `index` column to strings ('True' or 'False')
joint['index'] = joint['index'].astype(str)
# Convert the `crsp_fundno` column to strings, replacing NaN/None with an empty string or None
# Convert `crsp_fundno` to strings, replacing NaN/None with None
joint['crsp_fundno'] = joint['crsp_fundno'].astype(str).where(joint['crsp_fundno'].notnull(), None)
# Now try saving to Stata
print(joint.head())


joint["year"] = joint.index.get_level_values(1).year
#make dataframe with year-end dates only:
joint_y = joint[(joint.index.get_level_values(1).month == 12)].copy().reset_index().set_index(["year","port_id"])

#Sum up within years
yg = joint_y.groupby(level=0)
sumstats = yg[["qtna"]].sum()
sumstats["qtna_mean"] = yg["qtna"].mean()
sumstats["qtna_median"] = yg["qtna"].median()
sumstats["n_funds"] = yg.qtna.count()

#Add on full mkt cap
#Load pre-processed data (processed in script 2!)
crsp_m = pd.read_pickle("crsp_m.gz")[["permno","shrout","prc", "jdate"]]

print(crsp_m.head())
latest_jdate = crsp_m["jdate"].max()

crsp_m["prc"] = crsp_m.prc.abs() #Make prices all positive
crsp_y = crsp_m.loc[crsp_m.jdate.dt.month==(12),:].copy()
crsp_y["year"] = crsp_y.jdate.dt.year
crsp_y["mktcap_full"] = crsp_y.prc * crsp_y.shrout*1000
sumstats["mkt_cap_full"] = crsp_y.groupby("year").mktcap_full.sum()
sumstats["TNA_over_mktcap"] = sumstats["qtna"]/ (sumstats["mkt_cap_full"]/(10**6))


sumstats[["n_funds", "qtna_median", "qtna_mean","TNA_over_mktcap"]]
print(sumstats)


import matplotlib.pyplot as plt
# Assuming 'sumstats' DataFrame is already defined with the required columns
plt.figure(figsize=(10, 6))
# Plotting the number of funds over the years
plt.plot(sumstats.index, sumstats["n_funds"], marker='o')
# Setting title and labels
plt.title('Flow Data Fund Universe')
plt.xlabel('Year')
plt.ylabel('Number of Funds')
# Adding grid for better readability
plt.grid(True)
# Display the plot
plt.tight_layout()
plt.savefig('fund_classes_qdata_dec.png')
plt.savefig('flows_funds.pdf')
plt.show()



