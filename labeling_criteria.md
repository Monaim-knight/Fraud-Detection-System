# Dataset Labeling Criteria

## Label Definitions

### Fraud (Class = 1)
- **Confirmed chargebacks**: Transactions that resulted in confirmed chargebacks
- **Flagged fraudulent transactions**: Transactions that were explicitly flagged as fraudulent by the payment system or fraud detection mechanisms

### Non-Fraud (Class = 0)
- **Settled transactions**: Transactions that were successfully settled
- **No disputes after 90 days**: Transactions with no disputes filed within 90 days of the transaction date
- **Confirmed legitimate**: Transactions verified as legitimate through the settlement and dispute resolution process

### Ambiguous Cases (To be Excluded)
- **Pending investigations**: Transactions currently under investigation
- **Unresolved disputes**: Transactions with disputes that have not yet been resolved
- **Incomplete data**: Transactions where the fraud status cannot be definitively determined

## Labeling Process

1. **Initial Classification**: Based on transaction outcome
2. **90-Day Window**: Wait for dispute period to pass for non-fraud classification
3. **Exclusion**: Remove ambiguous cases that cannot be definitively classified
4. **Final Dataset**: Contains only clearly labeled Fraud (1) and Non-Fraud (0) cases

## Impact on Dataset

- **Original Dataset**: May contain ambiguous cases
- **Cleaned Dataset**: Should exclude ambiguous cases for model training
- **Model Training**: Only use definitively labeled cases to avoid label noise






