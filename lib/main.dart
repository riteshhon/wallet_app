import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:wallet_app/slider_widget.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wallet App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Wallet App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Client httpClient;
  late Web3Client ethClient;

  int myAmount = 0;
  bool data = false;
  final myAddress = "0xA17c7FC39275FCa043059c18Fcc3F05Cb87CEdE5";
  String txHash = "";
  var myData;

  @override
  void initState() {
    super.initState();
    httpClient = Client();
    ethClient = Web3Client(
        "https://rinkeby.infura.io/v3/6629d361e65f42b8a52afceda6fe4dd7",
        httpClient);

    getBalance(myAddress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0xc37592B4009474BFf1F2ED0E02c360e1128d5de2";

    final contract = DeployedContract(ContractAbi.fromJson(abi, "PKCoin"),
        EthereumAddress.fromHex(contractAddress));

    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);

    return result;
  }

  Future<void> getBalance(String targetAddress) async {
    // EthereumAddress address = EthereumAddress.fromHex(targetAddress);
    List<dynamic> result = await query("getBalance", []);

    myData = result[0];

    data = true;
    setState(() {});
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "4739dd62ca3e0527488b8b7d5ce54bdc14ffa0eed39d2b64a9e732082f382ab1");

    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract, function: ethFunction, parameters: args),
        fetchChainIdFromNetworkId: true);
    return result;
  }

  Future<String> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("depositeBalance", [bigAmount]);

    print("Deposited");
    txHash = response;
    setState(() {});
    return response;
  }

  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);

    var response = await submit("withdrawBalance", [bigAmount]);

    print("Withdrawn");
    txHash = response;
    setState(() {});
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Vx.gray300,
      body: ZStack([
        VxBox()
            .blue600
            .size(context.screenWidth, context.percentHeight * 30)
            .make(),
        VStack([
          (context.percentHeight * 10).heightBox,
          "Wallet App".text.xl4.white.bold.center.makeCentered().py16(),
          (context.percentHeight * 5).heightBox,
          VxBox(
                  child: VStack([
            "My Balance".text.gray700.xl2.semiBold.makeCentered(),
            5.heightBox,
            data
                ? "\$$myData".text.bold.xl6.makeCentered()
                : const CircularProgressIndicator().centered()
          ]))
              .p16
              .white
              .size(context.screenWidth, context.percentHeight * 22)
              .rounded
              .shadowXl
              .make()
              .p16(),
          30.heightBox,
          if (txHash != null) txHash.text.black.makeCentered().p16()
        ])
      ]),
    );
  }
}
