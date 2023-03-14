package myflinkapp;

public class TemperatureMeasurement {
    private String symbol;
    private Double minValue;

    public TemperatureMeasurement(String symbol, Double minValue) {
        this.symbol = symbol;
        this.minValue = minValue;
    }

    public String getSymbol() {
        return symbol;
    }

    public void setSymbol(String symbol) {
        this.symbol = symbol;
    }

    public Double getMinValue() {
        return minValue;
    }

    public void setMinValue(Double minValue) {
        this.minValue = minValue;
    }
}
