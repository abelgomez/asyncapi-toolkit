/**
 * generated by Xtext 2.17.0
 */
package io.github.abelgomez.asyncapi.asyncApi;

import org.eclipse.emf.common.util.EList;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Component</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link io.github.abelgomez.asyncapi.asyncApi.Component#getSchemas <em>Schemas</em>}</li>
 *   <li>{@link io.github.abelgomez.asyncapi.asyncApi.Component#getMessages <em>Messages</em>}</li>
 * </ul>
 *
 * @see io.github.abelgomez.asyncapi.asyncApi.AsyncApiPackage#getComponent()
 * @model
 * @generated
 */
public interface Component extends AbstractComponent
{
  /**
   * Returns the value of the '<em><b>Schemas</b></em>' containment reference list.
   * The list contents are of type {@link io.github.abelgomez.asyncapi.asyncApi.AbstractSchema}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Schemas</em>' containment reference list.
   * @see io.github.abelgomez.asyncapi.asyncApi.AsyncApiPackage#getComponent_Schemas()
   * @model containment="true"
   * @generated
   */
  EList<AbstractSchema> getSchemas();

  /**
   * Returns the value of the '<em><b>Messages</b></em>' containment reference list.
   * The list contents are of type {@link io.github.abelgomez.asyncapi.asyncApi.AbstractMessage}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Messages</em>' containment reference list.
   * @see io.github.abelgomez.asyncapi.asyncApi.AsyncApiPackage#getComponent_Messages()
   * @model containment="true"
   * @generated
   */
  EList<AbstractMessage> getMessages();

} // Component