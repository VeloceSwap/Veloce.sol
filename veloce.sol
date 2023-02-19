// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Interfejs dla fabryki par Uniswap
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// Interfejs dla routera Uniswap
interface IUniswapV2Router {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

// Kontrakt SafeMoon
contract SafeMoon {
    // Nazwa tokenu
    string public name = "SafeMoon";
    // Symbol tokenu
    string public symbol = "SAFEMOON";
    // Całkowita liczba dostępnych tokenów
    uint256 public totalSupply = 1000000000000000;
    // Liczba miejsc po przecinku tokenu
    uint8 public decimals = 9;

    // Mapa przechowująca saldo każdego posiadacza tokenu
    mapping(address => uint256) public balanceOf;
    // Mapa przechowująca pozwolenia na przesyłanie tokenu między adresami
    mapping(address => mapping(address => uint256)) public allowance;
    // Mapa przechowująca adresy, które są zwolnione z opłat transakcyjnych
    mapping(address => bool) public isFeeExempt;
    // Mapa przechowująca adresy, które są zwolnione z limitu transakcyjnego
    mapping(address => bool) public isTxLimitExempt;
    // Mapa przechowująca adresy, które są zwolnione z dystrybucji dywidendy
    mapping(address => bool) public isDividendExempt;

    // Całkowita liczba pobranych opłat transakcyjnych
    uint256 public totalFees;
    // Całkowita liczba posiadaczy tokenu
    uint256 public totalHolders;
    // Całkowita liczba sprzedających tokenu
    uint256 public totalSellers;

    // Opłata transakcyjna dla podatku
    uint256 public taxFee = 400;
    // Opłata transakcyjna dla płynności
    uint256 public liquidityFee = 400;
    // Opłata transakcyjna dla marketingu
    uint256 public marketingFee = 200;
    // Całkowita opłata transakcyjna
    uint256 public totalTaxFee = taxFee + liquidityFee + marketingFee;
    // Licznik do obliczania opłaty transakcyjnej
    uint256 public feeDenominator = 10000;
    
    // Odbiorca tokenów ze sprzedaży
address public autoLiquidityReceiver;
// Odbiorca opłat transakcyjnych dla marketingu
address public marketingFeeReceiver;

// Maksymalna liczba tokenów do przesłania w jednej transakcji
uint256 public maxTxAmount = totalSupply / 200; // 0.5% of total supply
// Minimalna liczba tokenów, po której transakcja spowoduje dodanie płynności
uint256 public numTokensSellToAddToLiquidity = totalSupply / 1000; // 0.1% of total supply

// Router Uniswap
IUniswapV2Router public uniswapV2Router;
// Para Uniswap dla tokenu
address public uniswapV2Pair;

// Czy funkcja swapowania tokenów jest włączona
bool public isSwapEnabled = true;

// Dystrybutor dywidendy
DividendDistributor public dividendDistributor;

// Czas uruchomienia kontraktu
uint256 public launchedAt;

// Czy opłaty transakcyjne są pobierane na normalnych transferach
bool public feesOnNormalTransfers = true;

// Czy handel jest otwarty
bool public tradingOpen = false;

// Zdarzenie wywoływane przy przesyłaniu tokenów
event Transfer(address indexed from, address indexed to, uint256 value);
// Zdarzenie wywoływane przy udzieleniu pozwolenia na przesyłanie tokenu między adresami
event Approval(address indexed owner, address indexed spender, uint256 value);
// Zdarzenie wywoływane przy włączeniu/wyłączeniu funkcji swapowania tokenów
event SwapEnabled(bool enabled);
// Zdarzenie wywoływane przy dodaniu płynności
event AutoLiquify(uint256 amountBNB, uint256 amount);
// Zdarzenie wywoływane przy aktualizacji dystrybutora dywidendy
event UpdatedDividendDistributor(address dividendDistributor);
// Zdarzenie wywoływane przy aktualizacji odbiorcy opłat transakcyjnych dla marketingu
event UpdatedMarketingFeeReceiver(address marketingFeeReceiver);
// Zdarzenie wywoływane przy aktualizacji odbiorcy tokenów ze sprzedaży
event UpdatedAutoLiquidityReceiver(address autoLiquidityReceiver);
// Zdarzenie wywoływane przy aktualizacji opłat transakcyjnych
event UpdatedFees(uint256 taxFee, uint256 liquidityFee, uint256 marketingFee);
// Zdarzenie wywoływane przy aktualizacji całkowitej opłaty transakcyjnej
event UpdatedTotalTaxFee(uint256 totalTaxFee);
// Zdarzenie wywoływane przy aktualizacji maksymalnej liczby tokenów do przesłania w jednej transakcji
event UpdatedMaxTxAmount(uint256 maxTxAmount);
// Zdarzenie wywoływane przy aktualizacji minimalnej liczby tokenów, po której transakcja spowoduje dodanie płynności
event UpdatedNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiqu
