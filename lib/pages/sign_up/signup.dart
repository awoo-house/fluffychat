import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:vrouter/vrouter.dart';

import 'package:fluffychat/pages/sign_up/signup_view.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import '../../utils/localized_exception_extension.dart';

class SignupPage extends StatefulWidget {
  final String? username;
  final VoidCallback? onRegistrationComplete;
  const SignupPage({Key? key, this.username, this.onRegistrationComplete})
      : super(key: key);

  @override
  SignupPageController createState() => SignupPageController();
}

class SignupPageController extends State<SignupPage> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordController2 = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? error;
  bool loading = false;
  bool showPassword = false;

  void toggleShowPassword() => setState(() => showPassword = !showPassword);

  String? get domain => Matrix.of(context).getLoginClient().homeserver!.host;
  String? get username =>
      widget.username ?? VRouter.of(context).queryParameters['username'];

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? password1TextFieldValidator(String? value) {
    const minLength = 8;
    if (value!.isEmpty) {
      return L10n.of(context)!.chooseAStrongPassword;
    }
    if (value.length < minLength) {
      return L10n.of(context)!.pleaseChooseAtLeastChars(minLength.toString());
    }
    return null;
  }

  String? password2TextFieldValidator(String? value) {
    if (value!.isEmpty) {
      return L10n.of(context)!.chooseAStrongPassword;
    }
    if (value != passwordController.text) {
      return L10n.of(context)!.passwordsDoNotMatch;
    }
    return null;
  }

  String? emailTextFieldValidator(String? value) {
    if (value!.isNotEmpty && !value.contains('@')) {
      return L10n.of(context)!.pleaseEnterValidEmail;
    }
    return null;
  }

  void signup([_]) async {
    setState(() {
      error = null;
    });
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
    });

    try {
      final client = Matrix.of(context).getLoginClient();
      final email = emailController.text;
      if (email.isNotEmpty) {
        Matrix.of(context).currentClientSecret =
            DateTime.now().millisecondsSinceEpoch.toString();
        Matrix.of(context).currentThreepidCreds =
            await client.requestTokenToRegisterEmail(
          Matrix.of(context).currentClientSecret,
          email,
          0,
        );
      }
      await client.uiaRequestBackground(
        (auth) => client.register(
          username: username!,
          password: passwordController.text,
          initialDeviceDisplayName: PlatformInfos.clientName,
          auth: auth,
        ),
      );
      widget.onRegistrationComplete?.call();
    } catch (e) {
      error = (e).toLocalizedString(context);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SignupPageView(this);
}
