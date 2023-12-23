import React, {useState} from 'react';
import {
  Button,
  NativeModules,
  SafeAreaView,
  ScrollView,
  StatusBar,
  useColorScheme,
  View,
} from 'react-native';
import {Colors, Header} from 'react-native/Libraries/NewAppScreen';

const {MusicKitModule} = NativeModules;

function App(): JSX.Element {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  const [title, setTitle] = useState(
    `Initial MusicKit status: "${MusicKitModule.currentAuthorizationStatus()}"`,
  );

  const onClick = async () => {
    const status = await MusicKitModule.requestAuthorization();
    setTitle(`MusicKit status: "${status}" at ${new Date().toLocaleString()}`);
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar
        barStyle={isDarkMode ? 'light-content' : 'dark-content'}
        backgroundColor={backgroundStyle.backgroundColor}
      />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={backgroundStyle}>
        <Header />
        <View
          style={{
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
          }}>
          <Button onPress={onClick} title={title} />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

export default App;
