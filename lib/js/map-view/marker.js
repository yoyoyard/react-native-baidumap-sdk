// @flow
import React from 'react'
import type { ComponentType } from 'react'
import PropTypes from 'prop-types'
import {
  ColorPropType,
  Platform,
  requireNativeComponent,
  StyleSheet,
  View,
  ViewPropTypes } from 'react-native'
import { LatLngPropType } from '../prop-types'
import Component from '../component'
import type { LatLng } from '../types'

const style = StyleSheet.create({
  marker: {
    position: 'absolute',
  },
})

type Props = {
  coordinate: LatLng,
  color?: ColorPropType,
  image?: string,
  view?: ComponentType<*>,
  title?: string,
  selected?: boolean,
  flat?: boolean,
} & ViewPropTypes

export default class Marker extends Component<Props> {
  static propTypes = {
    ...ViewPropTypes,
    coordinate: LatLngPropType.isRequired,
    color: ColorPropType,
    image: PropTypes.string,
    title: PropTypes.string,
    selected: PropTypes.bool,
    flat: PropTypes.bool,
  }

  componentDidUpdate() {
    if (this.props.view && Platform.OS === 'android') {
      this.update()
    }
  }

  nativeComponentName = 'BaiduMapMarker'

  select() {
    this.call('select')
  }

  update() {
    this.call('update')
  }

  renderMarkerView() {
    if (this.props.view) {
      // $FlowFixMe
      const markerView = <this.props.view />
      return (
        <View style={style.marker} key="marker">{markerView}</View>
      )
    }
    return null
  }

  render() {
    const props = {
      ...this.props,
      ...this.handlers(['onPress', 'onCalloutPress']),
      children: [this.props.children, this.renderMarkerView()],
    }
    return <BaiduMapMarker {...props} />
  }
}

const BaiduMapMarker = requireNativeComponent('BaiduMapMarker', Marker)