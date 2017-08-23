https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-application-objects

# Application and service principal objects in Azure AD

Sometimes the meaning of the term "application" can be misunderstood when used in the context of Azure AD. The goal of this article is to make it clearer, by clarifying conceptual and concrete aspects of Azure AD application integration, with an illustration of registration and consent for a multi-tenant application.

# Overview

An application that has been integrated with Azure AD has implications that go beyond the software aspect. "Application" is frequently used as a conceptual term, referring to not only the the application software, but also its Azure AD registration and role in authentication/authorization "conversations" at runtime. By definition, an application can function in a client role (consuming a resource), a resource server role (exposing APIs to clients), or even both. The conversation protocol is defined by an OAuth 2.0 Authorization Grant flow, allowing the client/resource to access/protect a resource's data respectively. Now let's go a level deeper, and see how the Azure AD application model represents an application at design-time and run-time.

## Application registration

When you register an Azure AD application in the Azure portal, two objects are created in your Azure AD tenant: an application object, and a service principal object.
Application object

An Azure AD application is defined by its one and only application object, which resides in the Azure AD tenant where the application was registered, known as the application's "home" tenant. The Azure AD Graph Application entity defines the schema for an application object's properties.
Service principal object

The service principal object defines the policy and permissions for an application's use in a specific tenant, providing the basis for a security principal to represent the application at run-time. The Azure AD Graph ServicePrincipal entity defines the schema for a service principal object's properties.
Application and service principal relationship

Consider the application object as the global representation of your application for use across all tenants, and the service principal as the local representation for use in a specific tenant. The application object serves as the template from which common and default properties are derived for use in creating corresponding service principal objects. An application object therefore has a 1:1 relationship with the software application, and a 1:many relationship with its corresponding service principal object(s).

A service principal must be created in each tenant where the application will be used, enabling it to establish an identity for sign-in and/or access to resources being secured by the tenant. A single-tenant application will have only one service principal (in its home tenant), usually created and consented for use during application registration. A multi-tenant Web application/API will also have a service principal created in each tenant where a user from that tenant has consented to its use.

## Note
Any changes you make to your application object, are also reflected in its service principal object in the application's home tenant only (the tenant where it was registered). For multi-tenant applications, changes to the application object are not reflected in any consumer tenants' service principal objects, until the access is removed via the Application Access Panel and granted again. 

Also note that native applications are registered as multi-tenant by default.

## Example
The following diagram illustrates the relationship between an application's application object and corresponding service principal objects, in the context of a sample multi-tenant application called HR app. There are three Azure AD tenants in this scenario:

<ol>
<li> Adatum - the tenant used by the company that developed the HR app
<li> Contoso - the tenant used by the Contoso organization, which is a consumer of the HR app
<li> Fabrikam - the tenant used by the Fabrikam organization, which also consumes the HR app Relationship between an application object and a service principal object
</ol>

<img src="https://docs.microsoft.com/en-us/azure/active-directory/develop/media/active-directory-application-objects/application-objects-relationship.png" maxwidth="900">

<b>Step 1</b> is the process of creating the application and service principal objects in the application's home tenant.

<b>Step 2</b>, when Contoso and Fabrikam administrators complete consent, a service principal object is created in their company's Azure AD tenant and assigned the permissions that the administrator granted. Also note that the HR app could be configured/designed to allow consent by users for individual use.

<b>Step 3</b>, the consumer tenants of the HR application (Contoso and Fabrikam) each have their own service principal object. Each represents their use of an instance of the application at runtime, governed by the permissions consented by the respective administrator.

## Next steps

An application's application object can be accessed via the Azure AD Graph API, the Azure portal's application manifest editor, or Azure AD PowerShell cmdlets, as represented by its OData Application entity.
An application's service principal object can be accessed via the Azure AD Graph API or Azure AD PowerShell cmdlets, as represented by its OData ServicePrincipal entity.
The Azure AD Graph Explorer is useful for querying both the application and service principal objects.

<ul>
<li>Create a SP with Powershell<br>
https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azurermps-4.3.1
<li>Create a SP with CLI 2.0</br>
https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?toc=%2fazure%2fazure-resource-manager%2ftoc.json
<li>Portal<br>
https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal
</ul>
