# Controle Financeiro — Flutter + Firebase

Versão Flutter do app web **Controle Financeiro** (gestão financeira individual e a dois),
com backend em **Firebase** (Firestore em tempo real + Auth anônimo).

## Passo a passo

### 1. Gerar as pastas nativas
Dentro desta pasta:

```bash
./setup.sh        # Mac/Linux      (no Windows: setup.bat)
```
Ele roda `flutter create`, ajusta o `minSdk` do Android para 23 e faz `flutter pub get`.
O comando gera as plataformas Android, iOS e Web. As pastas nativas já geradas podem ser
mantidas no projeto; rode o script novamente apenas se precisar recriá-las.

### 2. Criar o projeto no Firebase
1. Acesse https://console.firebase.google.com e crie um projeto.
2. **Authentication → Método de login → Anônimo → Ativar.**
3. **Firestore Database → Criar banco de dados** (modo produção).
4. No terminal:
   ```bash
   npm i -g firebase-tools && firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure          # escolhe o projeto e SUBSTITUI lib/firebase_options.dart
   firebase deploy --only firestore:rules
   ```
   (o `firebase.json` e o `firestore.rules` já estão na raiz; se o CLI pedir, rode `firebase use <id-do-projeto>`).

### 3. Rodar

Depois de executar `flutterfire configure` e configurar o Firebase:

```bash
# Android (com um emulador conectado)
flutter devices
flutter run -d <id-do-emulador>

# iOS (em um Mac com Xcode e CocoaPods instalados)
flutter run -d ios
```

O projeto inclui a estrutura nativa do iOS, mas o simulador e a compilação iOS só podem
ser executados em macOS com Xcode. No Windows, é possível gerar e versionar a pasta
`ios/`, mas não iniciar um simulador iOS localmente.

Sem um arquivo `lib/firebase_options.dart` gerado para o projeto Firebase, o app compila
e instala, mas falha na inicialização. Portanto, execute `flutterfire configure` antes
de testar o fluxo completo no Android ou no iOS.

```bash
flutter run
```
No primeiro acesso o app não cria dados de demonstração. Crie uma casa pelo próprio
aplicativo; ela começa com os membros Thiago e Mileni, salários zerados e sem
lançamentos.

## Como o app web foi mapeado

| App web (HTML/JS)                       | Flutter + Firebase                                              |
|-----------------------------------------|-----------------------------------------------------------------|
| `localStorage` (`stoco_households`)     | Firestore: `households/{CODIGO}` + subcoleções                  |
| Código da casa (isolamento)             | Documento por código; só entra quem conhece o código            |
| Simulador Online/Offline                | `disableNetwork()` / `enableNetwork()` do Firestore (real!)     |
| "N pendentes" / "Sincronizar agora"     | `metadata.hasPendingWrites` dos documentos                      |
| Tema claro/escuro                       | `ThemeMode` salvo em `shared_preferences`                       |
| "Dono deste celular"                    | `shared_preferences` (por aparelho e por casa)                  |
| Abas Home / Fixas & Renda / Extrato / Família | `lib/screens/tabs/*`                                      |
| Modais (lançamento, salários, fixa, casas) | `lib/dialogs/*`                                              |

### Estrutura de dados
```
households/{CODIGO}                    name, code, members[{name,salary,colorIndex}]
households/{CODIGO}/fixedExpenses/{id} title, amount, payer
households/{CODIGO}/transactions/{id}  title, amount, type, category, payer, date, createdAt,
                                      paymentMethod, installmentNumber, installmentTotal, recurringId
```

## Pequenas diferenças em relação ao app web
- **Mês no Extrato funcional:** as setas ‹ › agora trocam o mês e a Home calcula as
  variáveis do mês selecionado.
- **Código de casa novo** tem prefixo genérico e 6 caracteres alfanuméricos (ex.: `FAM-K7M2QX`) em vez de
  4 números, porque 4 dígitos seriam fáceis de adivinhar num backend real.
- "Criar / Conectar a Novo Código" agora permite **criar** *ou* **conectar** a um código existente.
- Ao criar uma casa, o código é confirmado no Firebase e pode ser copiado para conectar outro celular.
- Compras no cartão podem ser parceladas; cada parcela é gravada no mês correspondente do extrato.
- Salários/rendas cadastrados geram lançamentos de renda fixa para o mês atual e os próximos 11 meses.
- Lançamentos, despesas fixas e rendas fixas permitem informar Débito, Pix, Crédito ou Dinheiro.
- No Crédito, é possível escolher à vista ou parcelado; parcelas futuras preservam o dia escolhido,
  ajustando automaticamente para o último dia do mês quando necessário.
- O extrato pode ser gerado em PDF e compartilhado pelo menu do celular; no Android, o menu também
  permite salvar o arquivo em uma pasta ou aplicativo.
- Alterações de entradas, saídas, rendas, despesas fixas e pessoas geram avisos sincronizados para
  os aparelhos conectados à mesma casa enquanto o app está aberto.
- Excluir lançamento/fixa: a lixeira fica sempre visível (no celular não existe *hover*).
- Tema claro com fundo claro (no web o fundo ficava escuro mesmo no modo claro).
- Mantido igual ao web: lançamentos do tipo **Entrada** aparecem na lista mas **não entram**
  no cálculo da sobra (só salário − fixas − variáveis de saída).

## Segurança
`firestore.rules` exige login (anônimo), **proíbe listar casas** e não permite apagar casas.
Quem tem o código acessa a casa — igual ao modelo do app web. Para algo mais forte
no futuro (convites, e-mail/Google login, regras por membro), dá para evoluir a partir daqui.
